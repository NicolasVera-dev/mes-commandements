# Mes Commandements

Une application Flutter de suivi d'objectifs et d'habitudes, centrée sur une expérience mobile fluide. Créez vos « commandements », suivez vos cycles (jour/semaine/mois/année), personnalisez vos cartes et consultez l'historique détaillé de progression.

---

## Fonctionnalités

- 🔐 **Authentification complète** : inscription, connexion, réinitialisation de mot de passe, paramètres de compte
- ✅ **Gestion des commandements** : création, édition, suppression, reset manuel
- 📈 **Suivi visuel de progression** : barre dynamique, micro-animations, état complété/non complété
- 🔁 **Reset automatique par fréquence** : quotidien, hebdomadaire, mensuel, annuel
- 🧭 **Page détail riche** : historique par période, résumé de cycles réussis/échoués, navigation temporelle
- 🔥 **Badge de série (streak)** : sur chaque carte et dans le détail, un seul pill (emoji + libellé) sous le titre — série de **cycles passés** consécutifs (succès si au moins un `complete` par cycle, échec si cycle passé sans `complete` dans l’historique Firestore) ; priorité *reprise aujourd’hui* → succès (paliers par fréquence) → échecs (seuil ≥ 3) ; calcul dans `ComputeStreakUseCase`, données via `watchEventsFrom` sur les événements
- 🗂️ **Historique d'événements** : enregistrement des actions (`increment`, `complete`, `resetAuto`, `resetManual`) pour chaque commandement
- 🎨 **Personnalisation** : emoji, couleur d'accent, tags, ordre manuel par drag & drop
- 🔍 **Recherche, filtres et tri** : fréquence, statut, tags, recherche texte en direct
- ☁️ **Synchronisation Firestore en temps réel** par utilisateur connecté
- 🔔 **Rappels locaux** (optionnels) : notifications intelligentes par fréquence pour les commandements non terminés du cycle en cours ; réglage dans **Paramètres du compte** (activation, heure globale) ; préférences en local (`SharedPreferences`), pas dans Firestore ; **désactivés par défaut**
- 🌙 **UI Material 3 dark** et support multi-plateformes (Android, iOS, Web, Windows, macOS, Linux)

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
    └── notifications/
        ├── data/
        ├── domain/
        └── presentation/
```

- **Domain** : entités métier (`Command`, événements, fréquence), interfaces repository, règles/use cases, contrat `NotificationScheduler` et calcul des créneaux de rappel
- **Data** : implémentations Firebase Auth, Firestore (commandements, événements, nettoyage des données compte), planificateur de notifications locales et préférences de rappels
- **Presentation** : providers d'état, pages et widgets UI (auth, liste, détail, édition, visualisations de cycles, badges de série, carte de réglage des rappels)

---

## Prérequis

- [Flutter](https://flutter.dev/docs/get-started/install) avec **Dart SDK ^3.11.3** (contrainte `environment` du `pubspec.yaml`)
- Compte / projet **Firebase** (Auth + Firestore) — le dépôt inclut `lib/firebase_options.dart` pour la config courante ; pour un nouveau projet, régénérez ce fichier avec la [CLI FlutterFire](https://firebase.google.com/docs/flutter/setup)
- Pour Android : Android Studio / SDK (le build active le *core library desugaring* requis par les notifications locales)
- Pour iOS / macOS : Xcode
- Pour Windows : Visual Studio avec les workloads C++

---

## Installation

```bash
# Cloner le dépôt
git clone https://github.com/NicolasVera-dev/mes-commandements.git
cd mes-commandements

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
├── firebase_options.dart                                    # Configuration Firebase générée
├── app/
│   ├── app_root.dart                                        # Listener reset auto → AuthGate → HomePage
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
    └── commands/
        ├── data/repositories/
        │   ├── firestore_command_repository.dart
        │   └── firestore_command_event_repository.dart
        ├── domain/
        │   ├── entities/                                    # command, events, périodes, reset report...
        │   ├── repositories/                                # contrats command / command_event
        │   ├── services/                                    # génération des clés de cycle
        │   └── usecases/                                    # filtres, cycles, résumés, streak, reset...
        └── presentation/
            ├── pages/                                       # home, détail, édition
            ├── state/command_provider.dart
            ├── utils/                                       # style des visualisations de cycles
            └── widgets/                                     # cartes, filtres, calendriers, barres, streak…
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

---

## Rappels locaux (résumé)

- **Où** : écran **Paramètres du compte**, section « Rappels », après « Apparence ».
- **Comportement** : une notification par **fréquence** (quotidien, hebdomadaire, mensuel, annuel) uniquement s’il reste au moins un commandement **non complété** (`progress < target`) pour cette fréquence ; replanification après sync Firestore et après les actions qui changent la progression.
- **Défaut** : rappels **désactivés** ; heure par défaut **18:00** (locale) une fois activés.
- **Créneaux** (à l’heure choisie, fuseau de l’appareil) : quotidien chaque jour ; hebdomadaire mercredi et dimanche ; mensuel 7 jours et 2 jours avant la fin du mois ; annuel 1er novembre et 1er décembre.
- **Plateformes** : planification effective sur Android, iOS et macOS ; pas de rappels sur Web dans l’implémentation actuelle.
- **Android** : permissions et receivers nécessaires sont déclarés dans `AndroidManifest.xml` (notifications, alarmes exactes, redémarrage pour la replanification côté système).

---
