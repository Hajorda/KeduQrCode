import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  colorScheme: ColorScheme.fromSwatch().copyWith(
    brightness: Brightness.light,
    primary: const Color.fromARGB(255, 0, 0, 0),
    secondary: const Color.fromARGB(255, 0, 0, 0),
    surface: const Color.fromARGB(255, 255, 255, 255),
  ),
  useMaterial3: true,
);

ThemeData darkMode = ThemeData(
  colorScheme: ColorScheme.fromSwatch().copyWith(
   brightness: Brightness.dark,
  primary: Colors.grey[900],
  secondary: Colors.grey[800],
  surface: Colors.grey[700]
  ),
  useMaterial3: true,
);

