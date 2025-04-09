import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    brightness: Brightness.dark, // Chỉ định rõ brightness
    background: Colors.black,
    primary: Colors.blueGrey,
    secondary: Colors.teal,
    tertiary: Colors.grey,
    inversePrimary: Colors.white,
  ),
  scaffoldBackgroundColor: Colors.black,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
);