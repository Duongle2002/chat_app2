import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    brightness: Brightness.light, // Chỉ định rõ brightness
    background: Colors.white,
    primary: Colors.blue,
    secondary: Colors.blueAccent,
    tertiary: Colors.grey,
    inversePrimary: Colors.black,
  ),
  scaffoldBackgroundColor: Colors.white,
);