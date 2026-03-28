import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../commands/presentation/state/command_provider.dart';
import '../../data/notification_preferences_service.dart';
import '../../domain/notification_scheduler.dart';

/// Réglages des rappels locaux (activation + heure).
class NotificationSettingsCard extends StatefulWidget {
  const NotificationSettingsCard({super.key});

  @override
  State<NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard> {
  bool _prefsHydrated = false;
  late bool _enabled;
  late int _hour;
  late int _minute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_prefsHydrated) {
      return;
    }
    _prefsHydrated = true;
    final p = context.read<NotificationPreferencesService>();
    _enabled = p.remindersEnabled;
    _hour = p.reminderHour;
    _minute = p.reminderMinute;
  }

  String _timeLabel() {
    final h = _hour.toString().padLeft(2, '0');
    final m = _minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefs = context.read<NotificationPreferencesService>();
    final scheduler = context.read<NotificationScheduler>();

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rappels',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Activer les rappels'),
              subtitle: Text(
                'Une notification par type de fréquence (quotidien, hebdo, mensuel, annuel) '
                'lorsqu’il reste au moins un commandement non terminé pour la période en cours.',
                style: theme.textTheme.bodySmall,
              ),
              value: _enabled,
              onChanged: (value) async {
                      if (value) {
                        await scheduler.requestPermission();
                        await prefs.setRemindersEnabled(true);
                        if (!context.mounted) {
                          return;
                        }
                        setState(() => _enabled = true);
                        final commands =
                            context.read<CommandProvider>().commands;
                        unawaited(scheduler.rescheduleAll(commands));
                      } else {
                        await prefs.setRemindersEnabled(false);
                        if (!context.mounted) {
                          return;
                        }
                        setState(() => _enabled = false);
                        unawaited(scheduler.cancelAll());
                      }
                    },
            ),
            if (_enabled) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Heure du rappel'),
                subtitle: Text(
                  'Tous les créneaux utilisent cette heure (locale). Touchez pour modifier.',
                  style: theme.textTheme.bodySmall,
                ),
                trailing: Text(
                  _timeLabel(),
                  style: theme.textTheme.titleMedium,
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: _hour, minute: _minute),
                  );
                  if (picked == null || !context.mounted) {
                    return;
                  }
                  await prefs.setReminderHourMinute(picked.hour, picked.minute);
                  setState(() {
                    _hour = picked.hour;
                    _minute = picked.minute;
                  });
                  if (!context.mounted) {
                    return;
                  }
                  final commands = context.read<CommandProvider>().commands;
                  unawaited(scheduler.rescheduleAll(commands));
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
