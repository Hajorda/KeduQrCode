import 'dart:io';

import 'package:flutter/material.dart';
import 'package:tedu_qrcode/models/qr_code_data.dart';
import 'package:tedu_qrcode/services/wallpaper_service.dart';

/// Manages the state of the wallpaper overlay feature.
class WallpaperProvider extends ChangeNotifier {
  final WallpaperService _wallpaperService;

  bool _isAutoWallpaperSet = false;
  bool _isProcessing = false;
  String? _errorMessage;

  WallpaperProvider(this._wallpaperService);

  bool get isAutoWallpaperSet => _isAutoWallpaperSet;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;

  /// Enables or disables the wallpaper overlay for [data].
  /// On enable: composites QR onto wallpaper and sets it.
  /// On disable: restores the original wallpaper.
  Future<void> setAutoWallpaper({
    required bool enabled,
    required QrCodeData? data,
  }) async {
    _isAutoWallpaperSet = enabled;
    _errorMessage = null;
    _isProcessing = true;
    notifyListeners();

    if (enabled) {
      if (!Platform.isAndroid) {
        _errorMessage = 'Wallpaper auto-set is currently Android-only.';
        _isAutoWallpaperSet = false;
      } else if (data == null) {
        _errorMessage = 'No QR code available to set as wallpaper';
        _isAutoWallpaperSet = false;
      } else {
        final bool success = await _wallpaperService.setWallpaperWithQr(data);
        if (!success) {
          _errorMessage = 'Failed to set wallpaper';
          _isAutoWallpaperSet = false;
        }
      }
    } else {
      if (!Platform.isAndroid) {
        _errorMessage = 'Wallpaper auto-set is currently Android-only.';
      } else {
        final bool success = await _wallpaperService.restoreOriginalWallpaper();
        if (!success) {
          _errorMessage = 'Failed to restore original wallpaper';
        }
      }
    }

    _isProcessing = false;
    notifyListeners();
  }
}
