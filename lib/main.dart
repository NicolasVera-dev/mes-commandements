import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app/app_root.dart';
import 'app/command_card_layout_service.dart';
import 'app/theme_service.dart';
import 'app/user_preferences_service.dart';
import 'firebase_options.dart';
import 'features/commands/data/repositories/firestore_command_event_repository.dart';
import 'features/commands/data/repositories/firestore_command_repository.dart';
import 'features/commands/data/repositories/firestore_cycle_note_repository.dart';
import 'features/commands/domain/repositories/cycle_note_repository.dart';
import 'features/commands/domain/usecases/save_cycle_note_usecase.dart';
import 'features/commands/presentation/state/cycle_note_provider.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/firestore_account_data_cleanup_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/auth_provider.dart';
import 'features/commands/domain/repositories/command_event_repository.dart';
import 'features/commands/presentation/state/command_provider.dart';
import 'features/resistances/data/repositories/firestore_resistance_relapse_repository.dart';
import 'features/resistances/data/repositories/firestore_resistance_repository.dart';
import 'features/resistances/domain/repositories/resistance_relapse_repository.dart';
import 'features/resistances/domain/repositories/resistance_repository.dart';
import 'features/resistances/domain/usecases/record_resistance_relapse_usecase.dart';
import 'features/resistances/presentation/state/resistance_provider.dart';
import 'features/notifications/data/local_notification_scheduler.dart';
import 'features/notifications/data/notification_preferences_service.dart';
import 'features/notifications/domain/notification_scheduler.dart';

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CommandEventRepository commandEventRepository;
  final CycleNoteRepository cycleNoteRepository;
  final ThemeService themeService;
  final CommandCardLayoutService commandCardLayoutService;
  final UserPreferencesService userPreferencesService;
  final NotificationScheduler notificationScheduler;
  final NotificationPreferencesService notificationPreferencesService;

  /// Tests widget : même instance que [UserPreferencesService] pour éviter le vrai plugin.
  final FirebaseFirestore? firestoreOverride;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.commandEventRepository,
    required this.cycleNoteRepository,
    required this.themeService,
    required this.commandCardLayoutService,
    required this.userPreferencesService,
    required this.notificationScheduler,
    required this.notificationPreferencesService,
    this.firestoreOverride,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CommandEventRepository>.value(
          value: commandEventRepository,
        ),
        Provider<CycleNoteRepository>.value(
          value: cycleNoteRepository,
        ),
        ChangeNotifierProvider(
          create: (_) => CycleNoteProvider(
            repository: cycleNoteRepository,
            saveUseCase: SaveCycleNoteUseCase(cycleNoteRepository),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repository: authRepository,
            userPreferencesService: userPreferencesService,
          ),
        ),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<CommandCardLayoutService>.value(
          value: commandCardLayoutService,
        ),
        Provider<UserPreferencesService>.value(value: userPreferencesService),
        Provider<NotificationScheduler>.value(value: notificationScheduler),
        Provider<NotificationPreferencesService>.value(
          value: notificationPreferencesService,
        ),
        ChangeNotifierProvider(
          create: (_) => CommandProvider(
            repository: FirestoreCommandRepository(
              authRepository: authRepository,
              eventRepository: commandEventRepository,
              cycleNoteRepository: cycleNoteRepository,
              firestore: firestoreOverride,
            ),
            notificationScheduler: notificationScheduler,
          ),
        ),
        Provider<ResistanceRepository>(
          create: (_) => FirestoreResistanceRepository(
            authRepository: authRepository,
            firestore: firestoreOverride,
          ),
        ),
        Provider<ResistanceRelapseRepository>(
          create: (_) => FirestoreResistanceRelapseRepository(
            authRepository: authRepository,
            firestore: firestoreOverride,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            final repo = ctx.read<ResistanceRepository>();
            return ResistanceProvider(
              repository: repo,
              recordRelapseUseCase: RecordResistanceRelapseUseCase(repo),
            );
          },
        ),
      ],
      child: Consumer<ThemeService>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Mes commandements',
            themeMode: theme.themeMode,
            theme: theme.lightTheme,
            darkTheme: theme.darkTheme,
            home: const AppRoot(),
          );
        },
      ),
    );
  }
}

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  tz_data.initializeTimeZones();
  if (kIsWeb) {
    tz.setLocalLocation(tz.UTC);
  } else {
    try {
      final deviceTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTz.identifier));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Fuseau horaire local indisponible, repli UTC: $e');
        debugPrint('$st');
      }
      tz.setLocalLocation(tz.UTC);
    }
  }
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final sharedPrefs = await SharedPreferences.getInstance();
  final themeService = ThemeService(prefs: sharedPrefs);
  await themeService.loadSavedTheme();
  final commandCardLayoutService = CommandCardLayoutService(prefs: sharedPrefs);
  final userPreferencesService = UserPreferencesService(
    themeService: themeService,
    commandCardLayoutService: commandCardLayoutService,
  );
  final notificationPreferencesService =
      NotificationPreferencesService(sharedPrefs);
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await LocalNotificationScheduler.initializePlugin(
    flutterLocalNotificationsPlugin,
  );
  final notificationScheduler = LocalNotificationScheduler(
    plugin: flutterLocalNotificationsPlugin,
    preferences: notificationPreferencesService,
  );
  final accountDataCleanupRepository = FirestoreAccountDataCleanupRepository();
  final authRepository = FirebaseAuthRepository(
    accountDataCleanupRepository: accountDataCleanupRepository,
  );
  final commandEventRepository = FirestoreCommandEventRepository(
    authRepository: authRepository,
  );
  final cycleNoteRepository = FirestoreCycleNoteRepository(
    authRepository: authRepository,
  );
  FlutterNativeSplash.remove();
  runApp(
    MyApp(
      authRepository: authRepository,
      commandEventRepository: commandEventRepository,
      cycleNoteRepository: cycleNoteRepository,
      themeService: themeService,
      commandCardLayoutService: commandCardLayoutService,
      userPreferencesService: userPreferencesService,
      notificationScheduler: notificationScheduler,
      notificationPreferencesService: notificationPreferencesService,
    ),
  );
}