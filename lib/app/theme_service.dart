import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_theme.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'app.theme_mode';
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences _prefs;

  ThemeService({
    required SharedPreferences prefs,
  }) : _prefs = prefs;

  ThemeMode get themeMode => _themeMode;
  ThemeData get lightTheme => AppTheme.lightTheme();
  ThemeData get darkTheme => AppTheme.darkTheme();

  Future<void> loadSavedTheme() async {
    final saved = _prefs.getString(_themeModeKey);
    _themeMode = _themeModeFromStorage(saved);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveThemeModeLocally(mode);
  }

  Future<void> applyThemeModeFromStorageValue(String? value) async {
    final mode = _themeModeFromStorage(value);
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveThemeModeLocally(mode);
  }

  String toStorageValue(ThemeMode mode) {
    return _themeModeToStorage(mode);
  }

  ThemeMode fromStorageValue(String? value) {
    return _themeModeFromStorage(value);
  }

  Future<void> persistCurrentTheme() async {
    await _saveThemeModeLocally(_themeMode);
  }

  Future<void> _saveThemeModeLocally(ThemeMode mode) async {
    await _prefs.setString(_themeModeKey, _themeModeToStorage(mode));
  }

  ThemeMode _themeModeFromStorage(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

}
