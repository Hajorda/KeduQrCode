import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';

/// Handles all local persistence via SharedPreferences.
/// All keys are centralised in [AppConstants].
/// Every method catches exceptions and logs them rather than crashing.
class StorageService {
  // --- User Key ---

  Future<String?> getKey() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.prefKeyUserKey);
    } catch (e) {
      debugPrint('StorageService.getKey error: $e');
      return null;
    }
  }

  Future<void> saveKey(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefKeyUserKey, key);
    } catch (e) {
      debugPrint('StorageService.saveKey error: $e');
    }
  }

  Future<void> deleteKey() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefKeyUserKey);
    } catch (e) {
      debugPrint('StorageService.deleteKey error: $e');
    }
  }

  // --- Dynamic Boolean Settings ---
  
  Future<bool?> getBool(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key);
    } catch (e) {
      debugPrint('StorageService.getBool error: $e');
      return null;
    }
  }

  Future<void> saveBool(String key, bool value) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('StorageService.saveBool error: $e');
    }
  }

  // --- Wallpaper backup path ---

  Future<String?> getWallpaperPath() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.prefKeyWallpaperPath);
    } catch (e) {
      debugPrint('StorageService.getWallpaperPath error: $e');
      return null;
    }
  }

  Future<void> saveWallpaperPath(String path) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefKeyWallpaperPath, path);
    } catch (e) {
      debugPrint('StorageService.saveWallpaperPath error: $e');
    }
  }

  // --- Theme preference ---

  Future<bool> getIsDarkMode() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.prefKeyIsDarkMode) ?? false;
    } catch (e) {
      debugPrint('StorageService.getIsDarkMode error: $e');
      return false;
    }
  }

  Future<void> saveIsDarkMode(bool isDark) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefKeyIsDarkMode, isDark);
    } catch (e) {
      debugPrint('StorageService.saveIsDarkMode error: $e');
    }
  }
}
