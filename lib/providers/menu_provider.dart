import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/models/daily_menu.dart';
import 'package:tedu_qrcode/services/menu_service.dart';

/// Manages the state for the Günün Menüsü (daily menu) feature.
class MenuProvider extends ChangeNotifier {
  final MenuService _menuService;

  List<DailyMenu> _menus = [];
  bool _isLoading = false;
  String? _errorMessage;

  MenuProvider(this._menuService);

  // ── Getters ────────────────────────────────────────────────────────────────

  List<DailyMenu> get menus => _menus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasData => _menus.isNotEmpty;

  /// Today's menu, or null if not yet loaded / weekend / holiday.
  DailyMenu? get todayMenu {
    try {
      return _menus.firstWhere((m) => m.isToday);
    } catch (_) {
      return null;
    }
  }

  /// Index of today's menu in the list (for TabController initialIndex).
  int get todayIndex {
    final idx = _menus.indexWhere((m) => m.isToday);
    return idx >= 0 ? idx : 0;
  }

  // ── Init / Refresh ─────────────────────────────────────────────────────────

  /// Loads from cache or fetches fresh on app startup.
  Future<void> init() async {
    await _load(() => _menuService.loadMenus());
  }

  /// Force-fetches fresh data (pull-to-refresh or manual button).
  Future<void> refresh() async {
    await _load(() => _menuService.fetchAndCache());
  }

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _load(Future<List<DailyMenu>> Function() fetcher) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _menus = await fetcher();
      if (_menus.isEmpty) {
        _errorMessage = 'Menü verisi bulunamadı. Lütfen tekrar deneyin.';
      } else {
        await _pushToHomeWidget();
      }
    } catch (e) {
      debugPrint('MenuProvider error: $e');
      _errorMessage = 'Menü yüklenemedi. İnternet bağlantınızı kontrol edin.';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Saves today's menu items to the Android home screen widget via home_widget.
  Future<void> _pushToHomeWidget() async {
    try {
      final today = todayMenu;
      if (today == null) return;

      // Build a compact string like "Mercimek Çorbası\nKuru Fasulye\nPilav\nSütlaç"
      final summary = today.items.map((i) => i.name).take(4).join('\n');
      await HomeWidget.saveWidgetData<String>(
          AppConstants.prefKeyMenuData, DailyMenu.encodeList(_menus));
      await HomeWidget.saveWidgetData<String>('menu_today_summary', summary);
      await HomeWidget.saveWidgetData<String>(
          'menu_today_date', today.formattedDate);
      await HomeWidget.updateWidget(name: 'MenuWidgetProvider');
    } catch (e) {
      debugPrint('MenuProvider._pushToHomeWidget error: $e');
    }
  }
}
