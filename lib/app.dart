import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tedu_qrcode/constants/app_constants.dart';
import 'package:tedu_qrcode/providers/theme_provider.dart';
import 'package:tedu_qrcode/screens/home_screen.dart';
import 'package:tedu_qrcode/screens/not_found_screen.dart';
import 'package:tedu_qrcode/theme/app_theme.dart';

/// Root application widget. Reads [ThemeProvider] to switch themes.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: AppConstants.appName,
          theme: AppTheme.getLightTheme(themeProvider.seedColor),
          darkTheme: AppTheme.getDarkTheme(themeProvider.seedColor),
          themeMode: themeProvider.themeMode,
          home: const HomeScreen(),
          onUnknownRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => const NotFoundScreen(),
            );
          },
        );
      },
    );
  }
}
