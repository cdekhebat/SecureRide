// lib/models/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static final Map<String, ThemeData> themes = {
    'Classic': ThemeData(
      primaryColor: Color(0xFF6DAEDB),
      colorScheme: ColorScheme.light(
        primary: Color(0xFF6DAEDB),
        secondary: Color(0xFFF4A896),
      ),
      appBarTheme: AppBarTheme(
        color: Color(0xFF6DAEDB),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFF4A896),
      ),
    ),
    'Dark': ThemeData.dark(),
    'Light': ThemeData.light(),
  };
}