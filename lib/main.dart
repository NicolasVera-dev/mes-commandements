import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app_root.dart';
import 'app/theme_service.dart';
import 'app/user_preferences_service.dart';
import 'firebase_options.dart';
import 'features/commands/data/repositories/firestore_command_event_repository.dart';
import 'features/commands/data/repositories/firestore_command_repository.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/data/repositories/firestore_account_data_cleanup_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/auth_provider.dart';
import 'features/commands/domain/repositories/command_event_repository.dart';
import 'features/commands/presentation/state/command_provider.dart';

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final CommandEventRepository commandEventRepository;
  final ThemeService themeService;
  final UserPreferencesService userPreferencesService;

  const MyApp({
    super.key,
    required this.authRepository,
    required this.commandEventRepository,
    required this.themeService,
    required this.userPreferencesService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<CommandEventRepository>.value(
          value: commandEventRepository,
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            repository: authRepository,
            userPreferencesService: userPreferencesService,
          ),
        ),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        Provider<UserPreferencesService>.value(value: userPreferencesService),
        ChangeNotifierProvider(
          create: (_) => CommandProvider(
            repository: FirestoreCommandRepository(
              authRepository: authRepository,
              eventRepository: commandEventRepository,
            ),
          ),
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
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final sharedPrefs = await SharedPreferences.getInstance();
  final themeService = ThemeService(prefs: sharedPrefs);
  await themeService.loadSavedTheme();
  final userPreferencesService = UserPreferencesService(
    themeService: themeService,
  );
  final accountDataCleanupRepository = FirestoreAccountDataCleanupRepository();
  final authRepository = FirebaseAuthRepository(
    accountDataCleanupRepository: accountDataCleanupRepository,
  );
  final commandEventRepository = FirestoreCommandEventRepository(
    authRepository: authRepository,
  );
  FlutterNativeSplash.remove();
  runApp(
    MyApp(
      authRepository: authRepository,
      commandEventRepository: commandEventRepository,
      themeService: themeService,
      userPreferencesService: userPreferencesService,
    ),
  );
}