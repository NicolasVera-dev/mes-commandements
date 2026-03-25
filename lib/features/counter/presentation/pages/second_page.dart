import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.watch<CommandProvider>();
    final commands = commandProvider.commands;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes commandements'),
      ),
      body: commands.isEmpty
          ? Center(
              child: Text(
                'Aucun commandement.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: commands.length,
              separatorBuilder: (context, index) => SizedBox(
                height: 16,
                key: ValueKey(index),
              ),
              itemBuilder: (context, index) {
                final command = commands[index];
                final double progressRatio = command.target <= 0
                    ? 0.0
                    : command.progress / command.target;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                command.title,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: () {
                                commandProvider.deleteCommand(command.id);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progressRatio.clamp(0.0, 1.0),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${command.progress} / ${command.target}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fréquence: ${_frequencyLabel(command.frequency)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              commandProvider.incrementProgress(command.id);
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Incrémenter'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

String _frequencyLabel(Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return 'Quotidien';
    case Frequency.weekly:
      return 'Hebdomadaire';
    case Frequency.monthly:
      return 'Mensuel';
    case Frequency.yearly:
      return 'Annuel';
  }
}

