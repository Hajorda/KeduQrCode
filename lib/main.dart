import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/app.dart';
import 'package:tedu_qrcode/providers/qr_provider.dart';
import 'package:tedu_qrcode/providers/theme_provider.dart';
import 'package:tedu_qrcode/providers/wallpaper_provider.dart';
import 'package:tedu_qrcode/services/qr_service.dart';
import 'package:tedu_qrcode/services/storage_service.dart';
import 'package:tedu_qrcode/services/wallpaper_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: qrProvider),
        ChangeNotifierProvider(
          create: (_) => WallpaperProvider(wallpaperService),
        ),
      ],
      child: const App(),
    ),
  );
}
