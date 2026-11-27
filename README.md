# Rituel

Rituel aide à tenir ses engagements et à apprécier le travail accompli. L’application réunit trois espaces : les **Commandements** pour les habitudes à construire, les **Résistances** pour celles à éviter et le **Carnet de bord** pour organiser ses journées.

Application Flutter destinée à Android et iOS, avec synchronisation par compte Firebase. L’interface est disponible en français et en anglais, en thème clair, sombre ou système.

**Version du projet : `1.4.0+15`**, définie dans [pubspec.yaml](pubspec.yaml).

## Utiliser Rituel

La barre de navigation et le glissement horizontal donnent accès aux trois espaces. Les paramètres permettent de choisir la langue, le thème, la densité des cartes et les rappels. Le choix de langue est conservé au redémarrage.

Sans connexion, quatre pages présentent l’application. Elles défilent automatiquement toutes les huit secondes, sans compte à rebours visible, et restent accessibles par glissement manuel. Le défilement automatique est suspendu lorsque les réglages d’accessibilité l’exigent.

### Commandements : construire ses habitudes

- Créer un objectif quotidien, hebdomadaire, mensuel ou annuel, avec une cible, une description et, pour les objectifs quotidiens, des jours planifiés.
- Personnaliser les cartes avec un emoji, une couleur et des tags ; rechercher, filtrer, trier et réorganiser les commandements.
- Suivre sa progression, ses séries de succès ou d’échecs et son record de série dans le détail.
- Consulter la description complète et l’historique par cycle ; ajouter une note à chaque période.
- Mettre un commandement en pause, puis le reprendre immédiatement ou au prochain cycle : lendemain, semaine suivante, mois suivant ou année suivante selon sa fréquence.
- Masquer un commandement pour le retirer de la liste habituelle tout en conservant son historique. Le masquage le met en pause indéfinie. La section repliable **Commandements masqués** permet de le retrouver, le réafficher ou le supprimer définitivement. Le réaffichage conserve la pause.

Les actions de gestion sont regroupées dans le menu **…**. Les pauses neutralisent les cycles concernés et suspendent les rappels. Le filtre **En pause** permet de retrouver les commandements suspendus.

### Résistances : suivre les habitudes à éviter

- Créer une résistance avec une description, un emoji, une couleur et des tags.
- Suivre le nombre de jours sans rechute et son record ; un trophée apparaît lorsque la série dépasse le précédent record et reste visible jusqu’à la rechute.
- Enregistrer une rechute avec **J’ai craqué**, puis consulter l’historique et le calendrier.
- Ajouter, modifier ou supprimer une note sur une rechute, y compris après coup, sans modifier sa date ni la série associée. Chaque note est limitée à 300 caractères et sa suppression demande confirmation.
- Ajouter des notes par jour, rechercher et filtrer par tags, trier ou réorganiser les résistances.

Les séries de résistance comptent les jours calendaires UTC : le compteur est à zéro le jour de création ou de rechute. Le formulaire des notes de rechute est partagé avec celui des notes de commandement.

### Carnet de bord : planifier et faire le bilan

Créer une tâche, choisir sa date, lui donner une priorité si nécessaire, puis la cocher une fois accomplie. Les tâches ouvertes se réorganisent par appui long ; leur menu permet de les modifier, les replanifier ou les supprimer. La suppression est aussi disponible par glissement et peut être annulée pendant cinq secondes.

**Report et retard**

L’option **Reportable**, activée par défaut, reporte automatiquement une tâche inachevée aux jours suivants, avec son retard visible. Désactivée, la tâche reste attachée au jour prévu : si elle n’est pas accomplie, elle apparaît en échec dans cette journée et ne revient pas le lendemain.

Une replanification remet le délai de retard à zéro à la nouvelle date. Les engagements des journées passées sont conservés, y compris après une modification de l’option de report ou une suppression. Les dates du carnet suivent le calendrier local de l’appareil.

**Score quotidien**

Le score est la proportion de tâches accomplies parmi les tâches prévues ce jour-là, arrondie en pourcentage. Toutes les tâches ont le même poids ; la priorité est un repère visuel. Une tâche terminée mardi après avoir été prévue lundi reste inachevée dans le bilan du lundi et compte comme accomplie le mardi.

Une journée sans tâche reste sans score et ne compte ni comme une réussite ni comme un échec. Les journées passées affichent un bilan rétrospectif ; leurs tâches sont en lecture seule. Les journées futures servent à la planification.

**Calendrier et bilan personnel**

L’aperçu des sept derniers jours et le calendrier complet permettent de retrouver une journée. Le calendrier entoure les journées réussies en vert et les journées passées incomplètes en rouge. Aujourd’hui garde son propre contour ; les jours sans tâche restent neutres. Toucher l’en-tête du calendrier permet de changer d’année.

**Mon bilan** permet de conserver un ressenti et une note de 4 000 caractères maximum pour aujourd’hui ou une journée passée.

### Rappels

Les rappels locaux concernent les commandements encore incomplets. Ils sont désactivés par défaut et se règlent dans les paramètres, avec une heure commune, fixée par défaut à 18 h dans le fuseau de l’appareil.

Les créneaux dépendent de la fréquence : tous les jours pour le quotidien, mercredi et dimanche pour l’hebdomadaire, sept et deux jours avant la fin du mois pour le mensuel, les 1er novembre et 1er décembre pour l’annuel. Les commandements en pause ou masqués sont exclus.

## Développer en local

### Prérequis

- Flutter **3.47.9 minimum**, avec Dart **3.13.x** compatible avec la contrainte `^3.13.0`.
- Un projet Firebase avec **Authentication email/mot de passe** et **Cloud Firestore** activés.
- Pour Android : SDK Android et environnement Java compatibles avec la configuration Gradle du projet.
- Pour iOS : un Mac, Xcode compatible avec l’iOS de l’appareil et une équipe de signature Apple. La cible minimale de l’application est **iOS 15**. Les dépendances natives Firebase utilisent Swift Package Manager et nécessitent Swift 6.2 minimum.
- Pour les outils Firebase et les tests de règles : Node.js, Firebase CLI et Java 21 ou supérieur pour l’émulateur.

Les parcours de validation et de publication concernent Android et iOS. Le dépôt contient aussi des cibles Web et desktop ; leur présence ne garantit pas la prise en charge de toutes les fonctionnalités. Les rappels sont implémentés pour Android, iOS et macOS ; la configuration Firebase Linux n’est pas fournie.

### Installation et configuration Firebase

```bash
git clone git@github.com:NicolasVera-dev/mes-commandements.git
cd mes-commandements
git switch develop
mkdir -p build/ios/SourcePackages build/macos/SourcePackages
flutter pub get
```

Configurer ensuite le projet Firebase avec FlutterFire CLI :

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=ID_PROJET_FIREBASE
```

Les fichiers de configuration sont locaux et ignorés par Git :

- `lib/firebase_options.dart` ; un modèle est disponible dans `lib/firebase_options.example.dart`.
- `android/app/google-services.json` ; un modèle `.example` est fourni.
- `ios/Runner/GoogleService-Info.plist` et `macos/Runner/GoogleService-Info.plist` pour les cibles Apple concernées.

Utiliser les configurations du projet Firebase choisi. Ne pas remplacer une configuration locale fonctionnelle par un modèle. Le fichier `firebase.json` décrit la configuration du dépôt et doit correspondre au projet utilisé.

Publier les règles et index sur le projet Firebase choisi avant d’utiliser les données synchronisées :

```bash
npx --yes firebase-tools deploy --only firestore --project ID_PROJET_FIREBASE
```

### Lancer l’application

```bash
flutter doctor -v
flutter devices
flutter run -d ID_APPAREIL
```

Pour un iPhone, brancher et déverrouiller l’appareil, accepter la relation de confiance et activer le mode développeur. Ouvrir `ios/Runner.xcworkspace` dans Xcode et vérifier **Runner → Signing & Capabilities** : équipe Apple, signature automatique et identifiant `com.nvadev.rituel`.

Pour installer une version release autonome sur l’appareil :

```bash
flutter run --release -d ID_APPAREIL
```

Si la copie des plugins échoue après un `flutter clean`, recréer les dossiers `build/ios/SourcePackages` et `build/macos/SourcePackages`, puis relancer `flutter pub get`.

### Tests et analyse

```bash
flutter test
flutter analyze

# Contrôles ciblés du carnet de bord
flutter test test/features/journal
```

Les tests couvrent les règles métier, les repositories, les changements de compte et les parcours d’interface français/anglais, notamment sur petit écran et avec du texte agrandi.

Pour tester les règles Firestore avec un émulateur local, sans données de production :

```bash
npx --yes firebase-tools emulators:exec --only firestore --project demo-rituel-journal 'python3 test/firestore/journal_rules_test.py'
```

Les traductions se trouvent dans `lib/l10n/app_fr.arb` et `lib/l10n/app_en.arb`. Après modification, exécuter `flutter gen-l10n` et vérifier les deux langues. Les dépendances sont décrites dans `pubspec.yaml` et verrouillées dans `pubspec.lock` ; `flutter pub outdated` permet de contrôler leur état.

## Architecture et données

Flutter fournit l’interface Material 3, Provider la gestion d’état, Firebase Auth l’authentification et Firestore la persistance. Les préférences locales utilisent SharedPreferences ; les calendriers reposent sur TableCalendar et les rappels sur Flutter Local Notifications.

```text
lib/
├── main.dart
├── app/                 # Navigation, thème, préférences et composants communs
├── l10n/                # Traductions français / anglais
└── features/
    ├── auth/            # Compte et authentification
    ├── commands/        # Objectifs récurrents, cycles et séries
    ├── resistances/     # Séries sans rechute et notes
    ├── journal/         # Tâches, reports, scores et bilans
    └── notifications/   # Préférences et planification des rappels

test/                    # Tests métier, données, interface et règles Firestore
```

Chaque fonctionnalité sépare les règles métier et contrats dans **domain**, les implémentations de persistance dans **data**, et les pages, widgets et providers dans **presentation**. Les composants partagés, dont les fenêtres de création et le formulaire des notes, sont regroupés dans `lib/app`.

Les données sont rangées sous `users/{uid}` : commandements avec événements et notes de cycle, résistances avec rechutes et notes quotidiennes, tâches dans `journal_tasks` et bilans dans `journal_reflections`. Les règles de [firestore.rules](firestore.rules) limitent l’accès au compte propriétaire. La suppression du compte inclut le nettoyage de ces collections.

Les contenus sont actuellement stockés en clair dans Firestore : il n’y a pas de chiffrement de bout en bout côté application. La langue et les préférences de rappels sont conservées sur l’appareil.

## Compiler pour les stores

L’identifiant Android et iOS est **`com.nvadev.rituel`**. La version et le numéro de build viennent de `pubspec.yaml` (`versionName+versionCode` sur Android). Utiliser un numéro de build supérieur à ceux déjà envoyés aux stores.

### Android : bundle signé pour Google Play

Créer le fichier local `android/key.properties` avec la clé d’envoi attendue par Google Play :

```properties
storeFile=/chemin/absolu/vers/upload-keystore.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

Ce fichier, la clé privée et les fichiers de symboles doivent rester hors du dépôt.

```bash
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

Le bundle est généré dans `build/app/outputs/bundle/release/app-release.aab`. La configuration release active la signature, R8 et la réduction des ressources. Conserver les symboles de `build/debug-info/` et le fichier de correspondance R8 associé au build pour analyser les crashs.

Importer le bundle dans la Play Console et joindre les [notes de version français/anglais](docs/releases/1.4.0-play-store.txt). Une diffusion en test interne permet de vérifier l’installation et les parcours sur Android avant la publication.

### iOS : archive pour App Store Connect

Avec la configuration Firebase et la signature Apple renseignées :

```bash
flutter build ipa --release
```

Les archives et l’IPA sont générées sous `build/ios/`. La distribution App Store ou TestFlight nécessite les certificats et profils adaptés au compte Apple Developer.

## Organisation Git

- `develop` reçoit les versions intégrées par MR et sert de base au développement suivant.
- `codex/integration/X.Y` regroupe les fonctionnalités d’une version.
- `codex/feature/...` isole chaque fonctionnalité, fusionnée dans l’intégration après tests et validation sur appareil.
- `codex/release/X.Y.Z` prépare la version à publier et fait l’objet d’une MR vers `develop`.

Les sources versionnées incluent les fichiers de verrouillage des dépendances. Les configurations Firebase locales, clés de signature et artefacts de compilation restent exclus du dépôt.
