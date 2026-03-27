# Mes Commandements

Une application Flutter de suivi d'objectifs et d'habitudes, centrée sur une expérience mobile fluide. Créez vos « commandements », suivez vos cycles (jour/semaine/mois/année), personnalisez vos cartes et consultez l'historique détaillé de progression.

---

## Fonctionnalités

- 🔐 **Authentification complète** : inscription, connexion, réinitialisation de mot de passe, paramètres de compte
- ✅ **Gestion des commandements** : création, édition, suppression, reset manuel
- 📈 **Suivi visuel de progression** : barre dynamique, micro-animations, état complété/non complété
- 🔁 **Reset automatique par fréquence** : quotidien, hebdomadaire, mensuel, annuel
- 🧭 **Page détail riche** : historique par période, résumé de cycles réussis/échoués, navigation temporelle
- 🗂️ **Historique d'événements** : enregistrement des actions (`increment`, `complete`, `reset_auto`, `reset_manual`) pour chaque commandement
- 🎨 **Personnalisation** : emoji, couleur d'accent, tags, ordre manuel par drag & drop
- 🔍 **Recherche, filtres et tri** : fréquence, statut, tags, recherche texte en direct
- ☁️ **Synchronisation Firestore en temps réel** par utilisateur connecté
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
| Material Design 3 | Système de design |

---

## Architecture

Le projet suit l'architecture **Clean Architecture** avec une séparation stricte en couches :

```
lib/
├── app/
│   └── app_root.dart
└── features/
    ├── auth/
    │   ├── data/
    │   ├── domain/
    │   └── presentation/
    └── counter/
        ├── data/
        ├── domain/
        └── presentation/
```

- **Domain** : entités métier (`Command`, événements, fréquence), interfaces repository, règles/use cases
- **Data** : implémentations Firebase Auth / Firestore
- **Presentation** : providers d'état, pages et widgets UI (auth, home, détail, édition)

---

## Prérequis

- [Flutter SDK](https://flutter.dev/docs/get-started/install) ≥ 3.11.3
- Dart SDK (inclus avec Flutter)
- Pour Android : Android Studio / SDK
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
├── main.dart                                                # Initialisation app/Firebase/providers
├── app/
│   └── app_root.dart                                        # Composition racine (AuthGate + Home)
└── features/
    ├── auth/
    │   ├── data/repositories/firebase_auth_repository.dart
    │   ├── domain/repositories/auth_repository.dart
    │   └── presentation/
    │       ├── pages/                                       # login, signup, reset, compte
    │       ├── state/auth_provider.dart
    │       └── widgets/auth_gate.dart
    └── counter/
        ├── data/repositories/firestore_command_repository.dart
        ├── domain/
        │   ├── entities/                                    # command, events, reset report...
        │   ├── repositories/                                # contrats command/event repositories
        │   └── usecases/                                    # filtres, cycles, reset...
        └── presentation/
            ├── pages/                                       # home, détail, édition
            ├── state/command_provider.dart
            └── widgets/                                     # cards, sheets, filtres, animations
```

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
  final String emoji;
  final int? accentColorValue;
  final List<String> tags;
  final DateTime? createdAt;
}

enum Frequency { daily, weekly, monthly, yearly }

class CommandEvent {
  final String cycleKey;
  final CommandEventType type;
  final DateTime actionAtUtc;
}

enum CommandEventType { increment, complete, resetAuto, resetManual }
```

---
