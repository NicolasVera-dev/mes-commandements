/// Mode d’affichage des cartes de commandement sur l’écran d’accueil.
enum CommandCardDisplayMode {
  /// Carte complète (comportement historique de l’app).
  standard,

  /// Vue dense : moins de padding, informations essentielles.
  compact,
}

extension CommandCardDisplayModeStorage on CommandCardDisplayMode {
  String get storageKey {
    switch (this) {
      case CommandCardDisplayMode.standard:
        return 'standard';
      case CommandCardDisplayMode.compact:
        return 'compact';
    }
  }
}

/// Représentation stockée (prefs / Firestore) → enum. Inconnu ⇒ [standard].
CommandCardDisplayMode commandCardDisplayModeFromStorage(String? raw) {
  switch (raw) {
    case 'compact':
      return CommandCardDisplayMode.compact;
    case 'standard':
    default:
      return CommandCardDisplayMode.standard;
  }
}
