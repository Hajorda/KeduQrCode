import 'package:flutter/material.dart';

/// Defines the app's light and dark [ThemeData].
///
/// Uses [ColorScheme.fromSeed] which generates a harmonious Material 3
/// colour palette from a single seed colour.
class AppTheme {
  AppTheme._();

  static const Color _seedColor = Color(0xFF1565C0); // Deep blue

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      );
}
