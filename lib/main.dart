import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/counter/domain/entities/command.dart';
import 'features/counter/presentation/state/command_provider.dart';
import 'features/counter/presentation/pages/home_page.dart';

/// Commandements affichés lors de la première ouverture de l'application.
const List<Command> _defaultCommands = [
  Command(
    id: 'cmd-daily',
    title: 'Quotidien',
    target: 10,
    progress: 0,
    frequency: Frequency.daily,
  ),
  Command(
    id: 'cmd-weekly',
    title: 'Hebdomadaire',
    target: 6,
    progress: 0,
    frequency: Frequency.weekly,
  ),
  Command(
    id: 'cmd-monthly',
    title: 'Mensuel',
    target: 12,
    progress: 0,
    frequency: Frequency.monthly,
  ),
  Command(
    id: 'cmd-yearly',
    title: 'Annuel',
    target: 4,
    progress: 0,
    frequency: Frequency.yearly,
  ),
];

class MyApp extends StatelessWidget {
  final List<Command> initialCommands;

  const MyApp({super.key, required this.initialCommands});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CommandProvider(commands: initialCommands),
      child: MaterialApp(
        title: 'Mes commandements',
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(useMaterial3: true),
        home: const HomePage(),
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final saved = await CommandProvider.loadFromStorage();
  runApp(MyApp(initialCommands: saved ?? _defaultCommands));
}