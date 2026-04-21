import 'package:flutter/material.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tedu_qrcode/services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> geofenceCallback(GeofenceCallbackParams params) async {
  if (params.event == GeofenceEvent.enter) {
    debugPrint('Geofence entered! Firing notification...');
    await NotificationService.showGateNotification();
  }
}

class GeofenceService {
  static const double gateRadiusMeters = 20.0;

  static const List<Map<String, dynamic>> gates = [
    {'id': 'university_gate_1', 'lat': 39.923077, 'lng': 32.861222},
    {'id': 'university_gate_2', 'lat': 39.923666, 'lng': 32.861582},
    {'id': 'university_gate_3', 'lat': 39.924838, 'lng': 32.861596},
  ];

  static Future<void> initialize() async {
    try {
      await NativeGeofenceManager.instance.initialize();
    } catch (e) {
      debugPrint('Failed to initialize native_geofence: $e');
    }
  }

  /// Requests the necessary permissions sequentially for Android.
  static Future<bool> requestPermissions() async {
    // 1. Notification Permission
    var notificationStatus = await Permission.notification.request();
    if (!notificationStatus.isGranted) return false;

    // 2. Foreground Location Permission
    var locationStatus = await Permission.location.request();
    if (!locationStatus.isGranted) return false;

    // 3. Background Location Permission (Requires foreground location granted first)
    var bgLocationStatus = await Permission.locationAlways.request();
    if (!bgLocationStatus.isGranted) return false;

    return true;
  }

  static Future<bool> enableGateGeofence() async {
    final hasPermissions = await requestPermissions();
    if (!hasPermissions) {
      return false;
    }

    bool allSuccess = true;
    for (var gate in gates) {
      final geofence = Geofence(
        id: gate['id'] as String,
        location: Location(
            latitude: gate['lat'] as double, longitude: gate['lng'] as double),
        radiusMeters: gateRadiusMeters,
        triggers: const {GeofenceEvent.enter},
        androidSettings: const AndroidGeofenceSettings(
          initialTriggers: {GeofenceEvent.enter},
        ),
        iosSettings: const IosGeofenceSettings(
          initialTrigger: true,
        ),
      );

      try {
        await NativeGeofenceManager.instance.createGeofence(
          geofence,
          geofenceCallback,
        );
      } catch (e) {
        debugPrint('Failed to create geofence ${gate['id']}: $e');
        allSuccess = false;
      }
    }

    if (allSuccess) {
      debugPrint('Successfully created all gate geofences.');
    }
    return allSuccess;
  }

  static Future<void> disableGateGeofence() async {
    try {
      for (var gate in gates) {
        await NativeGeofenceManager.instance
            .removeGeofenceById(gate['id'] as String);
      }
      debugPrint('Successfully removed all gate geofences.');
    } catch (e) {
      debugPrint('Failed to remove geofences: $e');
    }
  }
}
