// lib/services/theme_service.dart
import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class ThemeService with ChangeNotifier {
  String _currentTheme = 'Classic';

  String get currentTheme => _currentTheme;
  ThemeData get currentThemeData => AppTheme.themes[_currentTheme]!;

  void changeTheme(String themeName) {
    _currentTheme = themeName;
    notifyListeners();
  }
}