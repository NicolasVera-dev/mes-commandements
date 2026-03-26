import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'features/counter/data/repositories/firestore_command_repository.dart';
import 'features/counter/presentation/state/command_provider.dart';
import 'features/counter/presentation/pages/home_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommandProvider(
        repository: FirestoreCommandRepository(),
      ),
      child: MaterialApp(
        title: 'Mes commandements',
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HomePage(),
      ),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}