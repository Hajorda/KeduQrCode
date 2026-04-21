import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/models/daily_menu.dart';
import 'package:tedu_qrcode/models/menu_item.dart';

/// Fetches and parses the Gençlik Sofrası weekly menu from Ankara municipality,
/// then caches the result in SharedPreferences for same-day reuse.
class MenuService {
  // ── HTTP ──────────────────────────────────────────────────────────────────

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'tr-TR,tr;q=0.9,en;q=0.8',
    'Referer': 'https://gencliksofralari.ankara.bel.tr/',
    'Cache-Control': 'no-cache',
  };

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the cached menu if it was fetched today; otherwise re-fetches.
  Future<List<DailyMenu>> loadMenus() async {
    try {
      final cached = await _loadFromCache();
      if (cached != null) return cached;
    } catch (e) {
      debugPrint('MenuService.loadMenus cache error: $e');
    }
    return fetchAndCache();
  }

  /// Force-fetches fresh data from the website, caches, and returns it.
  Future<List<DailyMenu>> fetchAndCache() async {
    final html = await _fetchHtml();
    final menus = _parseHtml(html);
    if (menus.isNotEmpty) {
      await _saveToCache(menus);
    }
    return menus;
  }

  // ── Cache ──────────────────────────────────────────────────────────────────

  Future<List<DailyMenu>?> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedDate = prefs.getString(AppConstants.prefKeyMenuDate);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (cachedDate != today) return null; // stale

    final json = prefs.getString(AppConstants.prefKeyMenuData);
    if (json == null || json.isEmpty) return null;

    final menus = DailyMenu.decodeList(json);
    debugPrint('MenuService: loaded ${menus.length} days from cache');
    return menus;
  }

  Future<void> _saveToCache(List<DailyMenu> menus) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString(AppConstants.prefKeyMenuData, DailyMenu.encodeList(menus));
    await prefs.setString(AppConstants.prefKeyMenuDate, today);
    debugPrint('MenuService: cached ${menus.length} days');
  }

  // ── Network ────────────────────────────────────────────────────────────────

  Future<String> _fetchHtml() async {
    final uri = Uri.parse(AppConstants.menuUrl);
    final response = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'MenuService: HTTP ${response.statusCode} from ${AppConstants.menuUrl}',
      );
    }
    return response.body;
  }

  // ── Parser ─────────────────────────────────────────────────────────────────

  /// Tries multiple selector strategies to extract a week's worth of menus.
  List<DailyMenu> _parseHtml(String rawHtml) {
    final document = html_parser.parse(rawHtml);

    // Strategy 1 — explicit table with date headers
    final fromTable = _parseFromTable(document);
    if (fromTable.isNotEmpty) {
      debugPrint('MenuService: parsed ${fromTable.length} days via table strategy');
      return fromTable;
    }

    // Strategy 2 — repeated card / section blocks
    final fromCards = _parseFromCards(document);
    if (fromCards.isNotEmpty) {
      debugPrint('MenuService: parsed ${fromCards.length} days via card strategy');
      return fromCards;
    }

    // Strategy 3 — flat list, group by Turkish day keywords
    final fromList = _parseFromList(document);
    if (fromList.isNotEmpty) {
      debugPrint('MenuService: parsed ${fromList.length} days via list strategy');
      return fromList;
    }

    debugPrint('MenuService: no menu data found in HTML');
    return [];
  }

  // ── Strategy 1: <table> ───────────────────────────────────────────────────

  List<DailyMenu> _parseFromTable(dom.Document doc) {
    final tables = doc.querySelectorAll('table');
    for (final table in tables) {
      final rows = table.querySelectorAll('tr');
      if (rows.length < 2) continue;

      // First row — try to find date headers
      final headerCells = rows.first.querySelectorAll('th, td');
      final dates = headerCells
          .map((c) => _tryParseDate(c.text.trim()))
          .toList();

      if (dates.every((d) => d == null)) continue; // not a menu table

      // Build a column-per-day structure
      final menusByColumn = <int, List<MenuItem>>{};
      for (var col = 0; col < dates.length; col++) {
        menusByColumn[col] = [];
      }

      for (final row in rows.skip(1)) {
        final cells = row.querySelectorAll('td');
        for (var col = 0; col < cells.length && col < dates.length; col++) {
          final text = cells[col].text.trim();
          if (text.isEmpty) continue;
          menusByColumn[col]!.add(MenuItem(
            name: text,
            category: _guessCategory(text),
          ));
        }
      }

      final result = <DailyMenu>[];
      for (var col = 0; col < dates.length; col++) {
        if (dates[col] != null && menusByColumn[col]!.isNotEmpty) {
          result.add(DailyMenu(date: dates[col]!, items: menusByColumn[col]!));
        }
      }
      if (result.isNotEmpty) return result;
    }
    return [];
  }

  // ── Strategy 2: cards / sections ─────────────────────────────────────────

  List<DailyMenu> _parseFromCards(dom.Document doc) {
    // Look for any element whose text starts with a Turkish date/day keyword
    final candidates = doc.querySelectorAll(
      'div, section, article, li, .card, .menu-day, .gun',
    );

    final result = <DailyMenu>[];
    for (final el in candidates) {
      final heading = el.querySelector('h1,h2,h3,h4,h5,strong,b,span.date,.tarih');
      if (heading == null) continue;

      final date = _tryParseDate(heading.text.trim());
      if (date == null) continue;

      final items = el
          .querySelectorAll('li, p, td, .menu-item, .yemek')
          .map((n) => n.text.trim())
          .where((t) => t.isNotEmpty && t.length > 2)
          .map((t) => MenuItem(name: t, category: _guessCategory(t)))
          .toList();

      if (items.isNotEmpty) {
        result.add(DailyMenu(date: date, items: items));
      }
    }
    return result;
  }

  // ── Strategy 3: flat list ─────────────────────────────────────────────────

  List<DailyMenu> _parseFromList(dom.Document doc) {
    final allText = doc.body?.text ?? '';
    final lines = allText
        .split(RegExp(r'[\n\r]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    DateTime? currentDate;
    List<MenuItem> currentItems = [];
    final result = <DailyMenu>[];

    for (final line in lines) {
      final date = _tryParseDate(line);
      if (date != null) {
        if (currentDate != null && currentItems.isNotEmpty) {
          result.add(DailyMenu(date: currentDate, items: List.from(currentItems)));
        }
        currentDate = date;
        currentItems = [];
      } else if (currentDate != null && line.length > 2) {
        currentItems.add(MenuItem(name: line, category: _guessCategory(line)));
      }
    }
    if (currentDate != null && currentItems.isNotEmpty) {
      result.add(DailyMenu(date: currentDate, items: currentItems));
    }
    return result;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static final _turkishMonths = {
    'ocak': 1, 'şubat': 2, 'mart': 3, 'nisan': 4,
    'mayıs': 5, 'haziran': 6, 'temmuz': 7, 'ağustos': 8,
    'eylül': 9, 'ekim': 10, 'kasım': 11, 'aralık': 12,
  };

  /// Tries to parse a Turkish date string such as:
  /// "21 Nisan 2025", "Pazartesi 21.04.2025", "21/04/2025", "2025-04-21"
  DateTime? _tryParseDate(String text) {
    final t = text.toLowerCase().trim();

    // ISO format: 2025-04-21
    final isoMatch = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(t);
    if (isoMatch != null) {
      return DateTime.tryParse(isoMatch.group(0)!);
    }

    // dd/mm/yyyy or dd.mm.yyyy
    final slashMatch =
        RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{4})').firstMatch(t);
    if (slashMatch != null) {
      return DateTime.tryParse(
        '${slashMatch.group(3)!}-'
        '${slashMatch.group(2)!.padLeft(2, '0')}-'
        '${slashMatch.group(1)!.padLeft(2, '0')}',
      );
    }

    // "21 nisan 2025" or "21 nisan" (assume current year)
    final turkishMatch =
        RegExp(r'(\d{1,2})\s+([a-zışğüöçı]+)(?:\s+(\d{4}))?').firstMatch(t);
    if (turkishMatch != null) {
      final day = int.tryParse(turkishMatch.group(1)!);
      final monthStr = turkishMatch.group(2)!;
      final month = _turkishMonths[monthStr];
      final year = int.tryParse(turkishMatch.group(3) ?? '') ??
          DateTime.now().year;
      if (day != null && month != null) {
        return DateTime(year, month, day);
      }
    }

    return null;
  }

  /// Heuristically maps a dish name to a broad category.
  String _guessCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('çorba') || n.contains('soup')) { return 'Çorba'; }
    if (n.contains('salata') || n.contains('salad')) { return 'Salata'; }
    if (n.contains('tatlı') || n.contains('sütlaç') || n.contains('kazandibi') ||
        n.contains('muhallebi') || n.contains('helva') || n.contains('baklava') ||
        n.contains('kadayıf') || n.contains('komposto')) { return 'Tatlı'; }
    if (n.contains('meyve') || n.contains('portakal') || n.contains('elma') ||
        n.contains('muz') || n.contains('mandalina')) { return 'Meyve'; }
    if (n.contains('ekmek') || n.contains('pide') || n.contains('lavaş')) {
      return 'Ekmek';
    }
    if (n.contains('pilav') || n.contains('makarna') || n.contains('bulgur') ||
        n.contains('erişte') || n.contains('patates') || n.contains('sebze') ||
        n.contains('zeytinyağlı') || n.contains('fasulye') ||
        n.contains('bezelye')) { return 'Garnitür'; }
    return 'Ana Yemek';
  }
}
