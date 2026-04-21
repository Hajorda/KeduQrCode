import 'package:flutter/material.dart';
import 'package:tedu_qrcode/services/geofence_service.dart';
import 'package:tedu_qrcode/services/storage_service.dart';

class GeofenceProvider extends ChangeNotifier {
  final StorageService _storageService;

  bool _isGeofenceEnabled = false;
  bool _isLoading = false;

  bool get isGeofenceEnabled => _isGeofenceEnabled;
  bool get isLoading => _isLoading;

  GeofenceProvider({required StorageService storageService})
      : _storageService = storageService;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Check if we previously enabled the geofence
    final bool? isEnabled = await _storageService.getBool('geofence_enabled');
    _isGeofenceEnabled = isEnabled ?? false;

    // Reactivate geofencing securely on start if the toggle was ON
    if (_isGeofenceEnabled) {
      final success = await GeofenceService.enableGateGeofence();
      if (!success) {
        // Drop it if permissions were revoked
        _isGeofenceEnabled = false;
        await _storageService.saveBool('geofence_enabled', false);
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> setGeofenceEnabled(bool enabled) async {
    _isLoading = true;
    notifyListeners();

    bool success = false;

    if (enabled) {
      success = await GeofenceService.enableGateGeofence();
      if (success) {
        _isGeofenceEnabled = true;
      }
    } else {
      await GeofenceService.disableGateGeofence();
      _isGeofenceEnabled = false;
      success = true;
    }

    if (success) {
      await _storageService.saveBool('geofence_enabled', _isGeofenceEnabled);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
