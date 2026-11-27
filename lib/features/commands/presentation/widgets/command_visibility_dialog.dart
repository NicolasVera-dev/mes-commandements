import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../domain/entities/command.dart';
import '../state/command_provider.dart';

/// Visibility and pause are saved together; showing never resumes silently.
Future<bool> showCommandVisibilityDialog(
  BuildContext context,
  Command command,
) async {
  final strings = context.l10n;
  final hidden = !command.isHidden;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(hidden ? strings.hideCommandTitle : strings.showCommandTitle),
      content: Text(
        hidden ? strings.hideCommandMessage : strings.showCommandMessage,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(strings.annuler),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(
            hidden ? strings.hideCommandAction : strings.showCommandAction,
          ),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  final provider = context.read<CommandProvider>();
  final messenger = ScaffoldMessenger.of(context);
  final success = await provider.setCommandHidden(command.id, hidden: hidden);
  if (!messenger.mounted) return success;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        success
            ? hidden
                  ? strings.commandHiddenFeedback
                  : strings.commandShownFeedback
            : strings.systemMessage(
                provider.syncErrorMessage ??
                    strings.cetteActionEstIndisponiblePourLeMoment,
              ),
      ),
    ),
  );
  return success;
}
