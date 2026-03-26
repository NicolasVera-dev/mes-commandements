import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'features/counter/data/repositories/firestore_command_repository.dart';
import 'features/auth/data/repositories/firebase_auth_repository.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/state/auth_provider.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/counter/presentation/state/command_provider.dart';

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;

  const MyApp({
    super.key,
    required this.authRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(repository: authRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CommandProvider(
            repository: FirestoreCommandRepository(
              authRepository: authRepository,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Mes commandements',
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final authRepository = FirebaseAuthRepository();
  runApp(MyApp(authRepository: authRepository));
}