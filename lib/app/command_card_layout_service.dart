import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'command_card_display_mode.dart';

/// Persistance locale du mode d’affichage des cartes (écran d’accueil).
class CommandCardLayoutService extends ChangeNotifier {
  static const String _prefsKey = 'app.command_card_display';

  final SharedPreferences _prefs;
  late CommandCardDisplayMode _displayMode;

  CommandCardLayoutService({required SharedPreferences prefs})
      : _prefs = prefs {
    _displayMode = commandCardDisplayModeFromStorage(_prefs.getString(_prefsKey));
  }

  CommandCardDisplayMode get displayMode => _displayMode;

  Future<void> setDisplayMode(CommandCardDisplayMode mode) async {
    if (_displayMode == mode) return;
    _displayMode = mode;
    notifyListeners();
    await _prefs.setString(_prefsKey, mode.storageKey);
  }

  /// Applique une valeur distante (Firestore) et aligne le stockage local.
  Future<void> applyFromStorageValue(String? value) async {
    final mode = commandCardDisplayModeFromStorage(value);
    if (mode == _displayMode) return;
    _displayMode = mode;
    notifyListeners();
    await _prefs.setString(_prefsKey, _displayMode.storageKey);
  }

  String toStorageValue(CommandCardDisplayMode mode) => mode.storageKey;
}
