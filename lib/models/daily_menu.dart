import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tedu_qrcode/models/menu_item.dart';

/// The complete menu for one day.
class DailyMenu {
  final DateTime date;
  final List<MenuItem> items;

  const DailyMenu({required this.date, required this.items});

  /// True when this menu's date is today's date.
  bool get isToday => DateUtils.isSameDay(date, DateTime.now());

  /// Localised day + date string, e.g. "Pazartesi, 21 Nisan".
  String get formattedDate =>
      DateFormat('EEEE, d MMMM', 'tr_TR').format(date);

  /// Short weekday label for tab headers, e.g. "Pzt".
  String get shortDay => DateFormat('E', 'tr_TR').format(date);

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    return DailyMenu(
      date: DateTime.parse(json['date'] as String),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };

  // ---------- list helpers --------------------------------------------------

  static String encodeList(List<DailyMenu> menus) =>
      jsonEncode(menus.map((m) => m.toJson()).toList());

  static List<DailyMenu> decodeList(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => DailyMenu.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
