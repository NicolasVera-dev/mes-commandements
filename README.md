# Mes Commandements

Une application Flutter de suivi d'objectifs et d'habitudes, centrée sur une expérience mobile fluide. Créez vos **commandements** (objectifs à répéter par cycle), vos **résistances** (habitudes à ne plus céder), personnalisez vos cartes et consultez l’historique (progression ou rechutes).

---

## Fonctionnalités

- 🔐 **Authentification complète** : inscription, connexion, réinitialisation de mot de passe, paramètres de compte
- ✅ **Gestion des commandements** : création, édition, suppression, reset manuel
- 📈 **Suivi visuel de progression** : barre dynamique, micro-animations, état complété/non complété
- 🔁 **Reset automatique par fréquence** : quotidien, hebdomadaire, mensuel, annuel
- 🧭 **Page détail riche** : historique par période, résumé de cycles réussis/échoués, navigation temporelle
- 📝 **Notes de cycle** : dans le détail, une note optionnelle par période de l’historique (jour, semaine, mois ou année) ; une icône discrète marque les périodes qui en ont une ; ouvrez-la en touchant la case ou la ligne ; tout est synchronisé avec le compte et supprimé avec le commandement
- 🔥 **Badge de série (streak)** : sur chaque carte et dans le détail, un seul pill (emoji + libellé) sous le titre — série de **cycles passés** consécutifs (succès si au moins un `complete` par cycle, échec si cycle passé sans `complete` dans l’historique Firestore) ; priorité *reprise aujourd’hui* → succès (paliers par fréquence) → échecs (seuil ≥ 3) ; calcul dans `ComputeStreakUseCase`, données via `watchEventsFrom` sur les événements
- 🗂️ **Historique d'événements** : enregistrement des actions (`increment`, `complete`, `resetAuto`, `resetManual`) pour chaque commandement
- 🎨 **Personnalisation** : emoji, couleur d'accent, tags, ordre manuel par drag & drop
- 🔍 **Recherche, filtres et tri** : fréquence, statut, tags, recherche texte en direct
- 🛡️ **Résistances** : liste dédiée pour ce que vous voulez arrêter ; **série en jours sans craquer** (compteur à **0** le jour de création, +1 par jour calendaire UTC ; le **record** suit la même règle au moment d’une rechute), action **« J’ai craqué »** bien visible (rouge d’erreur, **même teinte** en thème clair et sombre), rechute avec **note optionnelle**, fiche détail, historique, **notes par jour** sur le calendrier ; création / édition avec emoji (grille **orientée addictions** : tabac, alcool, écrans, jeux, etc.), couleur d’accent et tags
- 🔎 **Résistances — recherche & filtres** : même logique que l’accueil commandements (barre repliable, filtres par tags, tri manuel ou par série) ; **réordonnancement par glisser-déposer** uniquement en tri manuel, sans filtre ni recherche active
- 📐 **Affichage des cartes** (paramètres compte) : mode **Standard** ou **Compact** appliqué **aux commandements et aux résistances** (liste plus dense, cartes plus petites)
- ⌨️ **Saisie texte** : sur les formulaires commandements / résistances (titres, descriptions, notes associées aux rechutes ou aux jours), le clavier propose une **capitalisation type phrase** (première lettre) ; les **tags** restent en saisie libre (minuscules par défaut) ; les écrans **connexion / inscription / mot de passe** ne forcent pas ce comportement
- ☁️ **Synchronisation Firestore en temps réel** par utilisateur connecté
- 🔔 **Rappels locaux** (optionnels) : notifications intelligentes par fréquence pour les commandements non terminés du cycle en cours ; réglage dans **Paramètres du compte** (activation, heure globale) ; préférences en local (`SharedPreferences`), pas dans Firestore ; **désactivés par défaut**
- 🌙 **UI Material 3 dark** et support multi-plateformes (Android, iOS, Web, Windows, macOS, Linux)
- ↔️ **Navigation principale** : bascule **Commandements / Résistances** par la barre du bas ou par **glissement horizontal** entre les deux vues

---

## Stack technique

| Technologie | Rôle |
|---|---|
| [Flutter](https://flutter.dev) | Framework UI cross-platform |
| [Dart](https://dart.dev) | Langage de programmation |
| [Provider](https://pub.dev/packages/provider) | Gestion d'état (ChangeNotifier) |
| [firebase_core](https://pub.dev/packages/firebase_core) | Initialisation Firebase |
| [firebase_auth](https://pub.dev/packages/firebase_auth) | Authentification email/mot de passe |
| [cloud_firestore](https://pub.dev/packages/cloud_firestore) | Persistance temps réel |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Thème, préférences locales et options des rappels |
| [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications), [timezone](https://pub.dev/packages/timezone), [flutter_timezone](https://pub.dev/packages/flutter_timezone) | Planification des rappels locaux et fuseau horaire de l’appareil |
| [table_calendar](https://pub.dev/packages/table_calendar), [flex_color_picker](https://pub.dev/packages/flex_color_picker) | Calendriers et couleur d’accent dans les formulaires |
| Material Design 3 | Système de design |

---

## Architecture

Le projet suit l'architecture **Clean Architecture** avec une séparation stricte en couches :

```
lib/
├── app/
│   ├── app_root.dart
│   ├── app_theme.dart
│   ├── theme_service.dart
│   └── user_preferences_service.dart
└── features/
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── commands/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    ├── resistances/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── notifications/
        ├── data/
        ├── domain/
        └── presentation/
```

- **Domain** : entités métier (`Command`, événements, fréquence), interfaces repository, règles/use cases, contrat `NotificationScheduler` et calcul des créneaux de rappel
- **Data** : implémentations Firebase Auth, Firestore (commandements, événements, notes par cycle, **résistances**, rechutes, notes au jour, nettoyage des données compte), planificateur de notifications locales et préférences de rappels
- **Presentation** : providers d'état, pages et widgets UI (auth, navigation accueil commandements / résistances, listes, détail, édition, visualisations de cycles, badges de série, carte de réglage des rappels)

---

## Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install) avec **Dart SDK ^3.11.3** (contrainte `environment` du `pubspec.yaml`)
- Compte / projet **Firebase** (Auth + Firestore) — les fichiers sensibles ne sont pas versionnés : copiez `lib/firebase_options.example.dart` vers `lib/firebase_options.dart`, `android/app/google-services.json.example` vers `android/app/google-services.json`, puis exécutez `flutterfire configure` (ou collez les fichiers fournis par la console Firebase). Voir les commentaires en tête de `firebase_options.example.dart`.
- Pour Android : Android Studio / SDK (le build active le *core library desugaring* requis par les notifications locales)
- Pour iOS / macOS : Xcode
- Pour Windows : Visual Studio avec les workloads C++

---

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/NicolasVera-dev/mes-commandements.git
cd mes-commandements

# Fichiers Firebase locaux (non suivis par Git)
cp lib/firebase_options.example.dart lib/firebase_options.dart
cp android/app/google-services.json.example android/app/google-services.json
# Puis : flutterfire configure — ou remplir les fichiers avec votre projet Firebase

# Installer les dépendances
flutter pub get
```

---

## Lancer l'application

```bash
# Sur l'appareil par défaut
flutter run

# Sur une plateforme spécifique
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
```

---

## Build

```bash
flutter build apk       # Android (APK)
flutter build appbundle # Android (AAB)
flutter build ios       # iOS
flutter build web       # Web
flutter build windows   # Windows
flutter build macos     # macOS
flutter build linux     # Linux
```

---

## Android release (AAB) + obfuscation

Préparez d'abord la signature release Android avec le fichier `android/key.properties` (non versionné) :

```properties
storeFile=/absolute/path/to/your-upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Commande recommandée pour une build release durcie (R8 + shrink resources + obfuscation Dart) :

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Important :
- Conserver le dossier `build/debug-info/` dans un stockage privé sécurisé (nécessaire pour la symbolication des crashs obfusqués).
- Ne pas commiter ce dossier dans un dépôt public.

---

## Internal testing (Google Play Console)

1. Construire l'AAB :
   ```bash
   flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
   ```
2. Ouvrir la Play Console > `Testing` > `Internal testing`.
3. Créer une nouvelle release (`Create new release`) et uploader le fichier `.aab`.
4. Ajouter les testeurs (emails individuels ou Google Group).
5. Publier la release interne.
6. Installer l'app depuis le lien de test généré par Google Play.

Note : incrémenter `version` dans `pubspec.yaml` (`versionName+versionCode`) à chaque nouvel upload.

---

## Tests

```bash
# Lancer tous les tests
flutter test

# Avec couverture de code
flutter test --coverage

# Analyser le code
flutter analyze
```

---

## Structure des fichiers clés

```
lib/
├── main.dart                                                # Firebase, fuseau tz, notifications, MultiProvider
├── firebase_options.example.dart                            # Modèle sans secrets → copier en firebase_options.dart
├── firebase_options.dart                                    # Local uniquement (.gitignore), généré par FlutterFire
├── app/
│   ├── app_root.dart                                        # Listener reset auto → AuthGate → MainShell
│   ├── main_shell.dart                                      # PageView + NavigationBar (commandements / résistances)
│   ├── app_theme.dart
│   ├── theme_service.dart
│   └── user_preferences_service.dart
└── features/
    ├── auth/
    │   ├── data/repositories/
    │   │   ├── firebase_auth_repository.dart
    │   │   └── firestore_account_data_cleanup_repository.dart
    │   ├── domain/repositories/
    │   │   ├── auth_repository.dart
    │   │   └── account_data_cleanup_repository.dart
    │   └── presentation/
    │       ├── pages/                                       # login, signup, reset, compte
    │       ├── state/auth_provider.dart
    │       └── widgets/                                     # auth_gate, champs mot de passe, etc.
    ├── notifications/
    │   ├── data/
    │   │   ├── local_notification_scheduler.dart
    │   │   └── notification_preferences_service.dart
    │   ├── domain/
    │   │   ├── notification_scheduler.dart
    │   │   ├── reminder_slot_calculator.dart
    │   │   └── local_notification_ids.dart
    │   └── presentation/
    │       └── widgets/                                 # notification_settings_card (compte)
    ├── commands/
    │   ├── data/repositories/
    │   │   ├── firestore_command_repository.dart
    │   │   ├── firestore_command_event_repository.dart
    │   │   └── firestore_cycle_note_repository.dart
    │   ├── domain/
    │   │   ├── entities/                                    # command, events, périodes, reset report...
    │   │   ├── repositories/                                # contrats command / command_event / cycle_note
    │   │   ├── services/                                    # génération des clés de cycle
    │   │   └── usecases/                                    # filtres, cycles, résumés, streak, reset...
    │   └── presentation/
    │       ├── pages/                                       # home, détail, édition
    │       ├── state/command_provider.dart
    │       ├── utils/                                       # style des visualisations de cycles
    │       └── widgets/                                     # cartes, filtres, calendriers, barres, streak…
    └── resistances/
        ├── data/repositories/                               # Firestore résistance, rechute, note du jour
        ├── domain/                                          # entités, use cases (série, filtre/tri, rechute…)
        └── presentation/
            ├── pages/                                       # accueil, détail, édition
            ├── state/                                       # resistance_provider, day_note_provider
            └── widgets/                                     # carte, formulaires, filtres, dialogue rechute…
```

---

## Série (streak) — résumé

- **Où** : sous le titre sur la **carte** (liste) et dans la **carte d’en-tête** du **détail** ; style pill, couleurs sémantiques (succès / échec) via `AppSemanticColors`.
- **Règle** : uniquement des cycles **passés** (le cycle courant non terminé n’entre pas dans la série de succès). La série s’appuie sur les **clés présentes** dans les événements groupés par `cycleKey` (pas d’inférence sur les jours sans aucun événement en base).
- **Priorité d’un seul badge** : 1) reprise (succès ce cycle après échecs passés documentés) ; 2) série de succès ; 3) série d’échecs (affichée si ≥ 3 cycles consécutifs concernés) ; 4) aucun badge.
- **Seuils succès (ex. quotidien / hebdo)** : paliers à 3 / 6 / 10 / 30 cycles réussis consécutifs (mensuel et annuel : seuils adaptés dans le use case).
- **Fichiers principaux** : `lib/features/commands/domain/usecases/compute_streak_usecase.dart`, `presentation/widgets/command_streak_badge.dart`, `command_streak_from_repository.dart`, flux `CommandEventRepository.watchEventsFrom` dans `firestore_command_event_repository.dart`.
- **Données de test** : script optionnel `tool/seed_streak_test_data.dart` (connexion Auth + écriture Firestore) — voir l’en-tête du fichier pour les variables d’environnement `SEED_EMAIL`, `SEED_PASSWORD`, `SEED_CLEAN`.

---

## Modèle de données

```dart
class Command {
  final String id;
  final String title;
  final String description;
  final int target;
  final int progress;
  final Frequency frequency;
  final DateTime? lastResetAt;
  final DateTime? createdAt;
  final String emoji;
  final int? accentColorValue;
  final int position;
  final List<String> tags;
}

enum Frequency { daily, weekly, monthly, yearly }

class CommandEvent {
  final CommandEventType type;
  final DateTime actionAtUtc;
  final int progressAfterAction;
  final int targetAtAction;
  final String cycleKey;
}

enum CommandEventType { increment, resetAuto, resetManual, complete }
```

### Résistance (aperçu)

```dart
class Resistance {
  final String id;
  final String title;
  final String description;
  final DateTime createdAtUtc;
  final String emoji;
  final int? accentColorValue;
  final int position;
  final List<String> tags;
  final DateTime? lastRelapseAtUtc;
  final int bestStreakDays;
  // … sérialisation Firestore dans le code source
}
```

Les **rechutes** et les **notes par jour** sont stockées dans des collections dédiées (voir `firestore.rules` et les repositories sous `features/resistances/data/`).

---

## Rappels locaux (résumé)

- **Où** : écran **Paramètres du compte**, section « Rappels », après « Apparence ».
- **Comportement** : une notification par **fréquence** (quotidien, hebdomadaire, mensuel, annuel) uniquement s’il reste au moins un commandement **non complété** (`progress < target`) pour cette fréquence ; replanification après sync Firestore et après les actions qui changent la progression.
- **Défaut** : rappels **désactivés** ; heure par défaut **18:00** (locale) une fois activés.
- **Créneaux** (à l’heure choisie, fuseau de l’appareil) : quotidien chaque jour ; hebdomadaire mercredi et dimanche ; mensuel 7 jours et 2 jours avant la fin du mois ; annuel 1er novembre et 1er décembre.
- **Plateformes** : planification effective sur Android, iOS et macOS ; pas de rappels sur Web dans l’implémentation actuelle.
- **Android** : permissions et receivers nécessaires sont déclarés dans `AndroidManifest.xml` (notifications, alarmes exactes, redémarrage pour la replanification côté système).

---
