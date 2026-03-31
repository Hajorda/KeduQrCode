import 'package:flutter/material.dart';
import 'package:tedu_qrcode/services/storage_service.dart';

/// Manages the app theme (light/dark) and persists the user's choice.
class ThemeProvider extends ChangeNotifier {
  final StorageService _storageService;

  bool _isDarkMode = false;

  ThemeProvider(this._storageService);

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Loads the saved theme preference on app startup.
  Future<void> init() async {
    _isDarkMode = await _storageService.getIsDarkMode();
    notifyListeners();
  }

  /// Toggles between light and dark mode and persists the preference.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _storageService.saveIsDarkMode(_isDarkMode);
    notifyListeners();
  }
}
