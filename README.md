# Mes Commandements

Une application Flutter de suivi d'objectifs et d'habitudes. Créez vos propres « commandements » personnels, définissez des cibles et suivez votre progression au quotidien, à la semaine, au mois ou à l'année.

---

## Fonctionnalités

- ✅ **Créer** des commandements avec un titre, une cible et une fréquence
- 📈 **Suivre** la progression vers chaque objectif via une barre de progression visuelle
- 🔄 **Incrémenter** la progression d'un simple tap
- ✏️ **Modifier** les détails d'un commandement
- 🗑️ **Supprimer** un commandement avec confirmation
- 🔁 **Réinitialiser** la progression
- 🔍 **Filtrer** par fréquence (quotidien, hebdomadaire, mensuel, annuel)
- 🎯 **Filtrer** par statut (non commencé, en cours, terminé)
- ↕️ **Trier** par ordre alphabétique, progression ou état de complétion
- 🌙 Thème sombre Material Design 3
- 📱 Support multi-plateformes : Android, iOS, Web, Windows, macOS, Linux

---

## Stack technique

| Technologie | Rôle |
|---|---|
| [Flutter](https://flutter.dev) | Framework UI cross-platform |
| [Dart](https://dart.dev) | Langage de programmation |
| [Provider](https://pub.dev/packages/provider) | Gestion d'état (ChangeNotifier) |
| [flutter_bloc](https://pub.dev/packages/flutter_bloc) | Support du pattern BLoC |
| Material Design 3 | Système de design |

---

## Architecture

Le projet suit l'architecture **Clean Architecture** avec une séparation stricte en couches :

```
lib/
└── features/
    └── counter/
        ├── data/           # Couche données (implémentation des repositories)
        ├── domain/         # Couche domaine (entités, use cases, interfaces)
        └── presentation/   # Couche présentation (UI, state, widgets)
```

- **Domain** : entité `Command`, interface `CounterRepository`, use cases (`IncrementCounter`, `ResetCounter`)
- **Data** : implémentation en mémoire (`InMemoryCounterRepository`)
- **Presentation** : `CommandProvider` (ChangeNotifier), pages (`HomePage`, `EditCommandPage`), widgets (`CommandCard`, `CreateCommandSheet`, `FilterBottomSheet`)

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
├── main.dart                                      # Point d'entrée, initialisation Provider & thème
└── features/counter/
    ├── domain/
    │   ├── entities/command.dart                  # Modèle Command + enum Frequency
    │   ├── repositories/counter_repository.dart   # Interface repository
    │   └── usecases/                              # increment_counter, reset_counter
    ├── data/
    │   └── repositories/in_memory_counter_repository.dart
    └── presentation/
        ├── state/command_provider.dart            # État global (CommandProvider)
        ├── bloc/                                  # counter_bloc, events, state
        ├── pages/
        │   ├── home_page.dart                     # Page principale (liste + filtres)
        │   └── edit_command_page.dart             # Page d'édition d'un commandement
        └── widgets/
            ├── command_card.dart                  # Carte d'un commandement
            ├── create_command_sheet.dart          # Formulaire de création
            ├── filter_bottom_sheet.dart           # Panneau de filtres/tri
            └── filter_chips_bar.dart              # Barre de filtres actifs
```

---

## Modèle de données

```dart
class Command {
  final String id;
  final String title;
  final int target;      // Objectif à atteindre
  final int progress;    // Progression actuelle
  final Frequency frequency;
}

enum Frequency { daily, weekly, monthly, yearly }
```

---
