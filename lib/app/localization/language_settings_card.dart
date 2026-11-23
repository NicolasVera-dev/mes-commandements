import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/commands/presentation/state/command_provider.dart';
import '../../features/notifications/domain/notification_scheduler.dart';
import 'language_service.dart';
import 'localization.dart';

class LanguageSettingsCard extends StatefulWidget {
  const LanguageSettingsCard({super.key});

  @override
  State<LanguageSettingsCard> createState() => _LanguageSettingsCardState();
}

class _LanguageSettingsCardState extends State<LanguageSettingsCard> {
  bool _saving = false;

  Future<void> _change(String code) async {
    setState(() => _saving = true);
    try {
      await context.read<LanguageService>().setLanguage(code);
      if (!mounted) return;
      final scheduler = context.read<NotificationScheduler?>();
      final commands = context.read<CommandProvider?>();
      if (scheduler != null && commands != null) {
        await scheduler.rescheduleAll(commands.commands);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.laLangueNaPasPuEtreEnregistree)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageService>();
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.langue,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'fr', label: Text('Français')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {language.locale.languageCode},
              onSelectionChanged: _saving
                  ? null
                  : (values) => _change(values.single),
            ),
          ],
        ),
      ),
    );
  }
}
