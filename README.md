# Mes Commandements

Une application Flutter de suivi d'objectifs et d'habitudes, centrée sur une expérience mobile fluide. Créez vos **commandements** (objectifs à répéter par cycle), vos **résistances** (habitudes à ne plus céder), personnalisez vos cartes et consultez l’historique (progression ou rechutes).

---

## Fonctionnalités

- 👋 **Accueil déconnecté** : présentation en quatre pages (bienvenue, progression, résistances, carnet de bord), en-tête fixe avec logo et nom RITUEL, défilement automatique discret
- 🔐 **Authentification complète** : inscription, connexion, réinitialisation de mot de passe, paramètres de compte
- 🌐 **Langue de l’application** : français ou anglais depuis les paramètres, avec mémorisation du choix sur l’appareil
- 📓 **Carnet de bord** : troisième onglet pour planifier ses tâches, les accomplir, les réorganiser, les replanifier et les supprimer avec annulation ; report automatique avec retard, score quotidien, bilan personnel et aperçu des sept derniers jours
- ✅ **Gestion des commandements** : création, édition, suppression, reset manuel et masquage avec conservation de l’historique
- 📈 **Suivi visuel de progression** : barre dynamique, micro-animations, état complété/non complété
- 🔁 **Reset automatique par fréquence** : quotidien, hebdomadaire, mensuel, annuel
- 🧭 **Page détail riche** : historique par période, résumé de cycles réussis/échoués, navigation temporelle
- 📝 **Notes de cycle** : dans le détail, une note optionnelle par période de l’historique (jour, semaine, mois ou année) ; une icône discrète marque les périodes qui en ont une ; ouvrez-la en touchant la case ou la ligne ; tout est synchronisé avec le compte et supprimé avec le commandement
- 🔥 **Badge de série (streak)** : un badge sous le titre dans la liste et le détail. Huit paliers de réussite, huit paliers d’occasions manquées et un badge « Reprise ». Les seuils dépendent de la fréquence du commandement.
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

- [Flutter](https://flutter.dev/docs/get-started/install) **3.47.9 stable** avec **Dart SDK ^3.13.0** (version utilisée pour la mise à jour : Dart 3.13.7)
- Compte / projet **Firebase** (Auth + Firestore) — les fichiers sensibles ne sont pas versionnés : copiez `lib/firebase_options.example.dart` vers `lib/firebase_options.dart`, `android/app/google-services.json.example` vers `android/app/google-services.json`, puis exécutez `flutterfire configure` (ou collez les fichiers fournis par la console Firebase). Voir les commentaires en tête de `firebase_options.example.dart`.
- Pour Android : Android Studio / SDK (le build active le *core library desugaring* requis par les notifications locales)
- Pour iOS / macOS : Xcode avec Swift 6.2 minimum (requis par le SDK Firebase actuel). Pour un iPhone sous iOS 27 : **Xcode 27 et macOS Tahoe 26.6 minimum**, selon les [prérequis Apple](https://developer.apple.com/xcode/system-requirements/). La cible minimale de l’application est **iOS 15**.
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
mkdir -p build/ios/SourcePackages build/macos/SourcePackages
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
flutter run -d <identifiant-iphone> # iOS : identifiant donné par flutter devices
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
```

---

## Relancer sur un iPhone

1. Installer une version de macOS et de Xcode compatible avec l’iOS du téléphone (voir les prérequis ci-dessus), ouvrir Xcode et terminer l’installation de ses composants iOS.
2. Brancher l’iPhone en USB, le déverrouiller, accepter « Faire confiance » et activer le mode développeur dans Réglages → Confidentialité et sécurité.
3. Dans Xcode, ouvrir `ios/Runner.xcworkspace`, ajouter le compte Apple dans les réglages et vérifier l’équipe dans **Runner → Signing & Capabilities** (signature automatique, identifiant `com.nvadev.rituel`).
4. Vérifier que `lib/firebase_options.dart` contient la configuration Firebase réelle du projet ; ne pas écraser ce fichier local avec le modèle.
5. Exécuter :

```bash
flutter pub get
flutter doctor -v
flutter devices
flutter run -d <identifiant-iphone>

# Installation autonome sur le téléphone (sans débogueur)
flutter run --release -d <identifiant-iphone>
```

Les dépendances iOS utilisent Swift Package Manager ; Xcode les résout au premier build. Les fichiers `Package.resolved` sont versionnés pour reproduire les versions natives. Xcode 16.2 ne peut pas résoudre le SDK Firebase actuel (Swift 6.2 requis).

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

## Onboarding déconnecté (1.4)

L’accueil des utilisateurs déconnectés présente quatre pages : bienvenue, progression des commandements, résistances et carnet de bord. La dernière invite à planifier sa journée et à apprécier le travail accompli. Le logo d’application et le nom **RITUEL**, centrés en haut, restent fixes pendant les transitions. Le bouton **Commencer dès maintenant** reste accessible sur chaque page ; aucune attente n’est imposée avant la connexion.

Les pages défilent automatiquement toutes les huit secondes et reviennent à la première après le carnet de bord. Aucun compte à rebours ni bouton pause, reprise ou relecture n’est affiché. Les points indicateurs conservent leur dessin d’origine. Un swipe manuel relance un délai complet de huit secondes, et le minuteur est suspendu pendant une interaction tactile.

Le passage en arrière-plan ou l’ouverture de la connexion suspend le défilement. Avec la navigation accessible (lecteur d’écran) ou la réduction des animations, la présentation reste manuelle. Sur petit écran ou avec du texte agrandi, le contenu peut défiler verticalement, tandis que l’en-tête et les actions restent fixes. Les textes sont disponibles en français et en anglais.

```bash
flutter test test/features/auth/onboarding_welcome_test.dart
```

---

## Commandements masqués et filtre de pause (1.4)

Pour remplacer un objectif (par exemple passer de 7 000 à 8 000 pas) sans modifier son historique, ouvrir le menu **…** de sa carte ou de son détail, puis choisir **Masquer le commandement**. Après confirmation, il disparaît de la liste habituelle et passe en pause sans date de reprise. Son objectif, sa progression, ses événements et ses notes sont conservés. Une pause avec reprise programmée devient indéfinie : le commandement masqué ne reprend jamais automatiquement.

La section **Commandements masqués**, repliée par défaut en bas de la liste, permet de consulter le détail et l’historique, de **Réafficher** un commandement ou de le supprimer définitivement après confirmation. Elle reste accessible même si tous les commandements sont masqués. Réafficher conserve la pause ; l’action **Reprendre** permet ensuite de choisir une reprise immédiate ou au prochain cycle. La suppression définitive purge aussi les événements et notes, par lots pour les historiques volumineux.

Les commandements masqués ne déclenchent plus de rappels et ne subissent pas de reset automatique. Leur période de pause neutralise les cycles manqués selon les règles existantes des pauses, sans réécrire les cycles antérieurs. Le masquage est synchronisé avec le compte. Les anciens documents dépourvus du champ `isHidden` restent visibles.

Le filtre de statut **En pause** est disponible dans les filtres et leur barre de raccourcis. Ce statut prend le pas sur « Non démarrés », « En cours » et « Terminés » tant que la pause est active. Plusieurs statuts sélectionnés sont combinés par union. La recherche, la fréquence et les statuts s’appliquent aussi aux commandements masqués, qui restent dans leur section repliable.

---

## Cohérence mobile et records (1.4)

Les créations de commandement, résistance et tâche utilisent la même fenêtre : hauteur de 90 % de l’écran, respect de la zone sûre, poignée visible et clavier fermé à l’ouverture. Le clavier s’ouvre uniquement après sélection d’un champ. Les titres des trois pages principales partagent le même composant typographique. Le déplacement d’une tâche conserve sa carte sans ajouter de fond blanc.

Le détail d’un commandement affiche sa meilleure série de succès, calculée sur tout l’historique, avec les jours inactifs et les pauses neutralisés comme pour la série courante. Une résistance affiche un trophée lorsqu’elle dépasse le record à battre au début de sa série. Le trophée reste visible pendant cette série, même après synchronisation du record, et disparaît à la rechute. Égaler le précédent record ne suffit pas à le déclencher.

---

## Carnet de bord (1.4)

Le troisième onglet **Carnet de bord** sert à planifier des actions ponctuelles et à valoriser le travail accompli. Les commandements restent dédiés aux habitudes récurrentes et les résistances aux habitudes à éviter. L’interface du carnet est disponible en français et en anglais et reprend les thèmes clair et sombre de Rituel.

### Préparer et accomplir sa journée

- Ajouter une tâche avec le bouton **Nouvelle tâche**, choisir sa date (affichée « Prévue pour aujourd’hui » le jour même), son caractère reportable et, si utile, activer une priorité visuelle.
- Cocher une tâche pour la terminer aujourd’hui, ou la décocher le même jour pour la rouvrir. Les accomplissements sont regroupés dans une section dédiée avec une présentation verte, une progression animée et un retour haptique.
- Réorganiser les tâches ouvertes par appui long. Leur menu permet de modifier le titre et la priorité, de replanifier ou de supprimer.
- Supprimer par glissement ou depuis le menu, puis utiliser **Annuler** dans le bandeau pour restaurer la tâche le même jour. Le bandeau se ferme automatiquement après cinq secondes et peut être fermé immédiatement avec sa croix.
- Naviguer entre les dates avec les flèches ou le calendrier et revenir à **Aujourd’hui** en un toucher.

### Reports et historique

L’option **Reportable** est activée par défaut et peut être modifiée à la création ou à l’édition. Désactivée, la tâche n’apparaît que le jour prévu : si elle n’est pas accomplie, elle reste à 0 % dans le bilan de cette journée, avec une présentation d’échec, et ne revient pas le lendemain. Elle n’est pas supprimée de l’historique. Modifier l’option ne réécrit pas les engagements passés. Les tâches existantes restent reportables par défaut.


Les dates du carnet suivent le calendrier local de l’appareil. Une tâche ouverte **reportable** reste visible au fil des jours sans duplication ni écriture automatique à minuit. Ses périodes de planification permettent de conserver les scores passés lors d’une replanification. Une suppression retire la tâche du planning courant et futur, mais conserve ses engagements passés. Les tâches passées sont en lecture seule ; les notes de bilan restent modifiables.

Le retard indique le nombre de jours depuis le début de la période de planification active. Une replanification explicite fait repartir ce délai à la nouvelle date choisie ; la date d’origine reste conservée. Le carnet s’actualise au changement de jour et au retour dans l’application.

### Score et bilan personnel

Le score correspond au nombre de tâches accomplies ce jour-là divisé par le nombre de tâches prévues ce jour-là, arrondi en pourcentage. Chaque tâche a le même poids ; les priorités sont uniquement des repères visuels. À zéro, le compteur affiche **0 tâche accomplie sur X**. Une journée sans tâche n’a pas de score. Les tâches des jours futurs restent prévisionnelles : terminer une tâche aujourd’hui la retire des jours suivants.

Par exemple, une tâche prévue lundi et terminée mardi reste inachevée dans le bilan du lundi et compte comme accomplie le mardi. Supprimer ou replanifier une tâche lundi la retire du calcul du lundi ; effectuer cette action mardi ne modifie pas le score du lundi. Atteindre 100 % déclenche un message qui invite à apprécier le travail accompli.

**Mon bilan** permet d’enregistrer un ressenti facultatif et une note de 4 000 caractères maximum pour aujourd’hui ou une journée passée. L’enregistrement est explicite via **Enregistrer**. L’aperçu des sept derniers jours donne accès aux journées correspondantes et distingue les jours sans tâche des jours à 0 %.

### Persistance et vérifications

Le domaine se trouve dans `lib/features/journal/domain`, la persistance dans `data` et les composants Material dans `presentation`. Firestore stocke les tâches dans `users/{uid}/journal_tasks` et les bilans dans `users/{uid}/journal_reflections`. La suppression du compte purge aussi ces deux collections. Les règles de `firestore.rules` doivent être publiées avant un test sur un appareil connecté au projet Firebase.

Les tests Flutter du carnet couvrent les changements de jour, les reports et replanifications, les scores historiques, la suppression avec annulation, la persistance, le changement de compte et les parcours d’interface français/anglais, y compris sur petit écran et avec du texte agrandi :

```bash
flutter test test/features/journal
```

Tests locaux des règles de confidentialité (Java 21+, Node.js et Firebase CLI via npm ; aucune donnée de production utilisée) :

```bash
npx --yes firebase-tools emulators:exec --only firestore --project demo-rituel-journal 'python3 test/firestore/journal_rules_test.py'
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
- **Règle** : seuls les cycles depuis la création et les jours planifiés comptent. Un cycle réussi compte dès sa validation. Un cycle sans réussite compte comme manqué après sa clôture.
- **Priorité** : la première réussite après une occasion manquée affiche « Reprise » pour le cycle en cours. Les séries positives commencent à deux réussites et les séries négatives à une occasion manquée.
- **Seuils quotidiens** : 2, 3, 5, 7, 14, 30, 60 et 100 réussites, ou 1, 2, 3, 5, 7, 10, 14 et 21 occasions manquées. Le badge affiche la longueur réelle de la série. Les autres fréquences ont leurs propres seuils.
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


## Maintenance et branches

Les fonctionnalités d’une version partent de sa branche d’intégration : pour la 1.4, `codex/integration/1.4`. Chaque fonctionnalité dispose de sa branche `codex/feature/...`, est testée sur appareil, puis est fusionnée par PR dans la branche d’intégration après validation. La version complète rejoint `develop` une fois les fonctionnalités éprouvées. Les mises à jour de `develop` passent également par PR, conformément à la règle du dépôt.

La 1.3 est figée sur `codex/release/1.3.0` avec le tag `v1.3.0`. Les branches `v1.1.0` et `v1.2.0` restent des repères historiques. La branche `main`, qui contient un ancien squelette, reste inchangée dans ce cycle.

```bash
git switch codex/integration/1.4
git pull --ff-only origin codex/integration/1.4
git switch -c codex/feature/ma-fonctionnalite
```

Pour contrôler les dépendances : `flutter pub outdated`. Les dépendances indirectes verrouillées par Flutter ou d’autres paquets restent à la dernière version compatible, sans `dependency_overrides`. Après `flutter clean`, recréer les dossiers `build/ios/SourcePackages` et `build/macos/SourcePackages` avant `flutter pub get` si la copie des plugins échoue.

Les outils Android sont alignés sur Flutter 3.47.9 : Gradle 9.3.1, AGP 9.1.0 et Kotlin 2.4.0. Flutter conserve les modes de compatibilité `android.builtInKotlin=false` et `android.newDsl=false` pour les plugins. La cible Android est l’API 36 via les valeurs du SDK Flutter.

Avant une publication, augmenter `version` et le numéro de build dans `pubspec.yaml` selon la dernière version réellement envoyée aux stores, puis générer les artefacts signés :

```bash
flutter build ipa --release
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Les signatures, les déclarations de confidentialité et les fiches des stores doivent être vérifiées avant l’envoi. La mise à jour des dépendances ne constitue pas une validation par les stores.
