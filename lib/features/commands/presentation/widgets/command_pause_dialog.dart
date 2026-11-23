import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';
import '../utils/cycle_visual_style.dart';
import '../../../../app/localization/localization.dart';

enum _PauseAction { indefinitely, untilDate, resumeNow, resumeNextCycle }

Future<void> showCommandPauseDialog(
  BuildContext context,
  Command command,
) async {
  final l10n = context.l10n;

  final provider = context.read<CommandProvider>();
  final paused = command.isPausedAt(DateTime.now());
  final action = await showDialog<_PauseAction>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(paused ? l10n.reprendreLeCommandement : l10n.mettreEnPause),
      children: [
        if (paused) ...[
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, _PauseAction.resumeNow),
            child: Text(l10n.reprendreCeCycle),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, _PauseAction.resumeNextCycle),
            child: Text(l10n.reprendreAuProchainCycle),
          ),
        ] else ...[
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, _PauseAction.indefinitely),
            child: Text(l10n.jusquaCeQueJeReprenne),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, _PauseAction.untilDate),
            child: Text(l10n.choisirUneDateDeReprise),
          ),
        ],
      ],
    ),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _PauseAction.indefinitely:
      await provider.pauseCommand(command.id);
    case _PauseAction.untilDate:
      final now = DateTime.now().toUtc();
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      final date = await showDatePicker(
        context: context,
        helpText: l10n.dateDeReprise,
        builder: (context, child) => Localizations.override(
          context: context,
          locale: Locale(l10n.localeName),
          delegates: GlobalMaterialLocalizations.delegates,
          child: child,
        ),
        initialDate: tomorrow,
        firstDate: tomorrow,
        lastDate: DateTime(now.year + 10, now.month, now.day),
      );
      if (date == null || !context.mounted) return;
      await provider.pauseCommand(
        command.id,
        untilUtc: DateTime.utc(date.year, date.month, date.day),
      );
    case _PauseAction.resumeNow:
      await provider.resumeCommand(command.id, nextCycle: false);
    case _PauseAction.resumeNextCycle:
      await provider.resumeCommand(command.id, nextCycle: true);
  }

  if (!context.mounted) return;
  final error = provider.syncErrorMessage;
  if (error != null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.systemMessage(error))));
  }
}

class CommandPauseStatus extends StatelessWidget {
  const CommandPauseStatus({super.key, required this.command});

  final Command command;

  @override
  Widget build(BuildContext context) {
    final pause = command.pauseAt(DateTime.now());
    if (pause == null) return const SizedBox.shrink();
    final end = pause.endUtc;
    final date = end == null
        ? null
        : '${end.day} ${monthLabel(end.month, strings: context.l10n)} ${end.year}';
    return Text(
      date == null ? context.l10n.enPause : context.l10n.enPauseRepriseLe(date),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
