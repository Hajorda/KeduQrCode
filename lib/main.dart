import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/app.dart';
import 'package:tedu_qrcode/providers/qr_provider.dart';
import 'package:tedu_qrcode/providers/theme_provider.dart';
import 'package:tedu_qrcode/providers/wallpaper_provider.dart';
import 'package:tedu_qrcode/providers/geofence_provider.dart';
import 'package:tedu_qrcode/services/qr_service.dart';
import 'package:tedu_qrcode/services/storage_service.dart';
import 'package:tedu_qrcode/services/wallpaper_service.dart';
import 'package:tedu_qrcode/providers/menu_provider.dart';
import 'package:tedu_qrcode/services/menu_service.dart';
import 'package:tedu_qrcode/services/notification_service.dart';
import 'package:tedu_qrcode/services/geofence_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');

  await NotificationService.initialize();
  await GeofenceService.initialize();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Keep the screen on while the app is in use
  await WakelockPlus.enable();

  // --- Instantiate services ---
  final storageService = StorageService();
  final qrService = QrService();
  final wallpaperService = WallpaperService(
    qrService: qrService,
    storageService: storageService,
  );

  // --- Initialise providers that need async setup ---
  final themeProvider = ThemeProvider(storageService);
  await themeProvider.init();

  final qrProvider = QrProvider(
    storageService: storageService,
    qrService: qrService,
  );
  await qrProvider.init();

  final geofenceProvider = GeofenceProvider(
    storageService: storageService,
  );
  await geofenceProvider.init();

  final menuProvider = MenuProvider(MenuService());
  unawaited(menuProvider.init()); // fire-and-forget; screen handles loading state

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: qrProvider),
        ChangeNotifierProvider.value(value: geofenceProvider),
        ChangeNotifierProvider.value(value: menuProvider),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(wallpaperService),
        ),
      ],
      child: const App(),
    ),
  );
}
