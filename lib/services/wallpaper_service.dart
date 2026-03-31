import 'dart:io';
import 'dart:typed_data';

import 'package:access_wallpaper/access_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/models/qr_code_data.dart';
import 'package:tedu_qrcode/services/qr_service.dart';
import 'package:tedu_qrcode/services/storage_service.dart';

/// Handles all wallpaper reading, compositing, and writing.
/// All public methods return a bool result and never throw.
class WallpaperService {
  final QrService _qrService;
  final StorageService _storageService;

  WallpaperService({
    required QrService qrService,
    required StorageService storageService,
  })  : _qrService = qrService,
        _storageService = storageService;

  /// Requests required permissions and retrieves the current home screen wallpaper.
  /// Returns empty [Uint8List] if unavailable or permissions are denied.
  Future<Uint8List> getCurrentWallpaper() async {
    try {
      await _requestStoragePermissions();

      final bool granted = await _hasStoragePermission();
      if (!granted) {
        debugPrint('WallpaperService.getCurrentWallpaper: permission denied');
        return Uint8List(0);
      }

      final AccessWallpaper accessWallpaper = AccessWallpaper();
      final Uint8List? wallpaperBytes =
          await accessWallpaper.getWallpaper(AccessWallpaper.homeScreenFlag);

      if (wallpaperBytes == null) {
        debugPrint('WallpaperService.getCurrentWallpaper: wallpaper is null');
        return Uint8List(0);
      }
      return wallpaperBytes;
    } catch (e) {
      debugPrint('WallpaperService.getCurrentWallpaper error: $e');
      return Uint8List(0);
    }
  }

  /// Composites the QR code for [data] onto the current wallpaper and sets
  /// it as the lock screen. Returns true on success.
  Future<bool> setWallpaperWithQr(QrCodeData data) async {
    try {
      final File? qrFile = await _qrService.generateQrImage(data);
      if (qrFile == null) {
        debugPrint('WallpaperService.setWallpaperWithQr: QR generation failed');
        return false;
      }

      final Uint8List wallpaperBytes = await getCurrentWallpaper();
      if (wallpaperBytes.isEmpty) {
        debugPrint('WallpaperService.setWallpaperWithQr: wallpaper is empty');
        return false;
      }

      // Back up original wallpaper once
      final String? existingPath = await _storageService.getWallpaperPath();
      if (existingPath == null) {
        final File wallpaperFile = File('${qrFile.parent.path}/wallpaper.png')
          ..writeAsBytesSync(wallpaperBytes);
        await _storageService.saveWallpaperPath(wallpaperFile.path);
      }

      final img.Image? composited =
          _compositeQrOnWallpaper(wallpaperBytes, qrFile);
      if (composited == null) return false;

      final File newWallpaperFile =
          File('${qrFile.parent.path}/new_wallpaper.png')
            ..writeAsBytesSync(img.encodePng(composited));

      return WallpaperManager.setWallpaperFromFile(
          newWallpaperFile.path, WallpaperManager.LOCK_SCREEN);
    } catch (e) {
      debugPrint('WallpaperService.setWallpaperWithQr error: $e');
      return false;
    }
  }

  /// Restores the original wallpaper that was backed up before overlay.
  /// Returns true on success.
  Future<bool> restoreOriginalWallpaper() async {
    try {
      final String? wallpaperPath = await _storageService.getWallpaperPath();
      if (wallpaperPath == null) {
        debugPrint(
            'WallpaperService.restoreOriginalWallpaper: no backup found');
        return false;
      }

      final File backupFile = File(wallpaperPath);
      if (!backupFile.existsSync()) {
        debugPrint(
            'WallpaperService.restoreOriginalWallpaper: backup file missing');
        return false;
      }

      return WallpaperManager.setWallpaperFromFile(
          wallpaperPath, WallpaperManager.LOCK_SCREEN);
    } catch (e) {
      debugPrint('WallpaperService.restoreOriginalWallpaper error: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Future<void> _requestStoragePermissions() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) await Permission.storage.request();

    final manageStatus = await Permission.manageExternalStorage.status;
    if (!manageStatus.isGranted) {
      await Permission.manageExternalStorage.request();
    }
  }

  Future<bool> _hasStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted || status.isLimited;
  }

  /// Composites the QR image onto [wallpaperBytes] and returns the result.
  /// Returns null if any image decoding step fails.
  img.Image? _compositeQrOnWallpaper(Uint8List wallpaperBytes, File qrFile) {
    final img.Image? wallpaperImage = img.decodeImage(wallpaperBytes);
    if (wallpaperImage == null) {
      debugPrint('WallpaperService: failed to decode wallpaper image');
      return null;
    }

    final Uint8List qrBytes;
    try {
      qrBytes = qrFile.readAsBytesSync();
    } catch (e) {
      debugPrint('WallpaperService: failed to read QR file: $e');
      return null;
    }

    final img.Image? qrImage = img.decodeImage(qrBytes);
    if (qrImage == null) {
      debugPrint('WallpaperService: failed to decode QR image');
      return null;
    }

    // Give QR a white background (transparent by default)
    final img.Image qrWithBackground =
        img.Image(width: qrImage.width, height: qrImage.height);
    img.fill(qrWithBackground, color: img.ColorFloat64.rgb(255, 255, 255));
    img.compositeImage(qrWithBackground, qrImage);

    // Resize QR to defined fraction of wallpaper width
    final int qrWidth =
        (wallpaperImage.width * AppConstants.qrWallpaperWidthFraction).round();
    final img.Image resizedQr =
        img.copyResize(qrWithBackground, width: qrWidth);

    // Create black background with padding
    final int bgWidth =
        (resizedQr.width * AppConstants.qrBackgroundPadding).round();
    final int bgHeight =
        (resizedQr.height * AppConstants.qrBackgroundPadding).round();
    final img.Image background = img.Image(width: bgWidth, height: bgHeight);
    img.fill(background, color: img.ColorFloat64.rgb(0, 0, 0));

    // Center QR on background
    img.compositeImage(
      background,
      resizedQr,
      dstX: (bgWidth - resizedQr.width) ~/ 2,
      dstY: (bgHeight - resizedQr.height) ~/ 2,
    );

    // Center background on wallpaper
    img.compositeImage(
      wallpaperImage,
      background,
      dstX: (wallpaperImage.width - bgWidth) ~/ 2,
      dstY: (wallpaperImage.height - bgHeight) ~/ 2,
    );

    return wallpaperImage;
  }
}
