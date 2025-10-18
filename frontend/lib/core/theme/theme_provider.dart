import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _colorKey = 'theme_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = AppTheme.seaGreen;

  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadThemeSettings();
  }

  Future<void> _loadThemeSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeString = prefs.getString(_themeKey) ?? 'system';
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeModeString,
        orElse: () => ThemeMode.system,
      );

      // Load primary color
      final colorString = prefs.getString(_colorKey) ?? 'seagreen';
      _primaryColor = AppTheme.colorPalette[colorString] ?? AppTheme.seaGreen;

      notifyListeners();
    } catch (e) {
      // Hata olursa varsayılan değerleri kullan
      debugPrint('Theme settings load error: $e');
      _themeMode = ThemeMode.system;
      _primaryColor = AppTheme.seaGreen;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.name);
  }

  Future<void> setPrimaryColor(String colorKey) async {
    _primaryColor = AppTheme.colorPalette[colorKey] ?? AppTheme.seaGreen;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorKey, colorKey);
  }

  ThemeData getLightTheme() => AppTheme.getLightTheme(_primaryColor);
  ThemeData getDarkTheme() => AppTheme.getDarkTheme(_primaryColor);
}

