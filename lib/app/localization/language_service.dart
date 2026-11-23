import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends ChangeNotifier {
  LanguageService({required SharedPreferences preferences})
    : _preferences = preferences,
      _locale = preferences.getString(_storageKey) == 'en'
          ? const Locale('en')
          : const Locale('fr');

  static const _storageKey = 'app.language';
  final SharedPreferences _preferences;
  Locale _locale;

  Locale get locale => _locale;

  Future<void> setLanguage(String code) async {
    if (code != 'fr' && code != 'en') {
      throw ArgumentError.value(code, 'code', 'Unsupported language');
    }
    if (code == _locale.languageCode) return;
    final saved = await _preferences.setString(_storageKey, code);
    if (!saved) throw StateError('Unable to save language');
    _locale = Locale(code);
    notifyListeners();
  }
}
