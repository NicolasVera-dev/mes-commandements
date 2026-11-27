import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../domain/entities/command.dart';
import '../pages/command_detail_page.dart';
import '../state/command_provider.dart';
import 'command_confirmation_dialogs.dart';
import 'command_visibility_dialog.dart';

enum _HiddenCommandAction { show, details, delete }

class HiddenCommandsSection extends StatelessWidget {
  final List<Command> commands;
  const HiddenCommandsSection({super.key, required this.commands});

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) return const SizedBox.shrink();
    final strings = context.l10n;
    final theme = Theme.of(context);
    final provider = context.watch<CommandProvider>();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ExpansionTile(
        key: const PageStorageKey('hidden_commands_section'),
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: const Icon(Icons.visibility_off_outlined),
        title: Text(
          strings.hiddenCommandsTitle(commands.length),
          style: theme.textTheme.titleSmall,
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Text(
              strings.hiddenCommandsHelp,
              style: theme.textTheme.bodySmall,
            ),
          ),
          for (final command in commands)
            Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: Text(
                  command.emoji,
                  style: theme.textTheme.headlineSmall,
                ),
                title: Text(command.title),
                subtitle: Text(strings.hiddenCommandStatus),
                onTap: () => _openDetails(context, command.id),
                trailing: PopupMenuButton<_HiddenCommandAction>(
                  enabled: !provider.isMutating,
                  tooltip: strings.actionsDuCommandement,
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: _HiddenCommandAction.show,
                      child: Text(strings.showCommandAction),
                    ),
                    PopupMenuItem(
                      value: _HiddenCommandAction.details,
                      child: Text(strings.voirLeDetail),
                    ),
                    PopupMenuItem(
                      value: _HiddenCommandAction.delete,
                      child: Text(strings.supprimer),
                    ),
                  ],
                  onSelected: (action) async {
                    switch (action) {
                      case _HiddenCommandAction.show:
                        await showCommandVisibilityDialog(context, command);
                      case _HiddenCommandAction.details:
                        if (context.mounted) _openDetails(context, command.id);
                      case _HiddenCommandAction.delete:
                        if (await confirmCommandDeletion(context) &&
                            context.mounted) {
                          final success = await provider.deleteCommand(
                            command.id,
                          );
                          if (!success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  strings.systemMessage(
                                    provider.syncErrorMessage ??
                                        strings
                                            .cetteActionEstIndisponiblePourLeMoment,
                                  ),
                                ),
                              ),
                            );
                          }
                        }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context, String id) => Navigator.of(context)
      .push(
        MaterialPageRoute<void>(
          builder: (_) => CommandDetailPage(commandId: id),
        ),
      );
}
