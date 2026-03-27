import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/command.dart';
import '../pages/command_detail_page.dart';
import '../pages/edit_command_page.dart';
import '../state/command_provider.dart';
import 'dynamic_progress_bar.dart';
import 'increment_animation_overlay.dart';

class CommandCard extends StatefulWidget {
  final Command command;

  const CommandCard({
    super.key,
    required this.command,
  });

  @override
  State<CommandCard> createState() => _CommandCardState();
}

class _CommandCardState extends State<CommandCard> {
  Future<void> _confirmAndDelete({
    required BuildContext context,
    required CommandProvider commandProvider,
    required Command command,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer le commandement ?'),
          content: const Text(
            'Cette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      commandProvider.deleteCommand(command.id);
    }
  }

  List<TextSpan> _buildHighlightedSpans({
    required String text,
    required String query,
    required TextStyle baseStyle,
    required TextStyle highlightStyle,
  }) {
    final q = query.trim();
    if (q.isEmpty) {
      return <TextSpan>[TextSpan(text: text, style: baseStyle)];
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: baseStyle,
          ));
        }
        break;
      }

      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: baseStyle,
        ));
      }

      spans.add(TextSpan(
        text: text.substring(idx, idx + q.length),
        style: highlightStyle,
      ));

      start = idx + q.length;
      if (start >= text.length) break;
    }

    return spans;
  }

  @override
  void didUpdateWidget(covariant CommandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldCompleted = oldWidget.command.isCompleted();
    final newCompleted = widget.command.isCompleted();

    if (oldCompleted != newCompleted && newCompleted) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.read<CommandProvider>();
    final command = widget.command;
    final searchQuery = context.select<CommandProvider, String>(
      (p) => p.searchQuery,
    );
    final isCompleted = command.isCompleted();
    final hasCustomAccent = command.accentColorValue != null;
    final accentColor = command.accentColorValue == null
        ? Theme.of(context).colorScheme.primary
        : Color(command.accentColorValue!);

    final borderColor = isCompleted
        ? Colors.greenAccent.shade200.withValues(alpha: 0.55)
        : (hasCustomAccent
            ? accentColor.withValues(alpha: 0.5)
            : Colors.transparent);
    final cardBackgroundColor = isCompleted
        ? Colors.green.withValues(alpha: 0.12)
        : hasCustomAccent
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.08),
                Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : Theme.of(context).colorScheme.surfaceContainerHighest;
    final iconAccent = hasCustomAccent ? accentColor : null;

    return Material(
      type: MaterialType.card,
      elevation: isCompleted ? 4 : 2,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: IncrementAnimationOverlay(
        enabled: !isCompleted,
        onTap: () {
          commandProvider.incrementProgress(command.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final baseStyle = Theme.of(context).textTheme.titleMedium;
                        if (baseStyle == null) {
                          return Text(command.title);
                        }

                        final q = searchQuery.trim();
                        if (q.isEmpty) {
                          return Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: hasCustomAccent
                                      ? accentColor.withValues(alpha: 0.2)
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHigh,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Hero(
                                  tag: 'command-emoji-${command.id}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      command.emoji,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  command.title,
                                  style: baseStyle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          );
                        }

                        final highlightStyle = baseStyle.copyWith(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.22),
                          fontWeight: FontWeight.w600,
                        );

                        final spans = _buildHighlightedSpans(
                          text: command.title,
                          query: q,
                          baseStyle: baseStyle,
                          highlightStyle: highlightStyle,
                        );

                        return Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOut,
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: hasCustomAccent
                                    ? accentColor.withValues(alpha: 0.2)
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Hero(
                                tag: 'command-emoji-${command.id}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    command.emoji,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: spans),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      final curved =
                          CurvedAnimation(parent: animation, curve: Curves.easeOut);
                      return FadeTransition(
                        opacity: curved,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.8, end: 1).animate(curved),
                          child: child,
                        ),
                      );
                    },
                    child: isCompleted
                        ? Icon(
                            Icons.check_circle_rounded,
                            key: const ValueKey('completed'),
                            color: Colors.greenAccent.shade200,
                          )
                        : const SizedBox.shrink(key: ValueKey('incomplete')),
                  ),
                  PopupMenuButton<_CommandCardMenuAction>(
                    tooltip: 'Actions',
                    icon: const Icon(Icons.more_vert_rounded),
                    iconColor: iconAccent,
                    constraints: const BoxConstraints(
                      minWidth: 190,
                    ),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      tapTargetSize: MaterialTapTargetSize.padded,
                    ),
                    onSelected: (action) async {
                      switch (action) {
                        case _CommandCardMenuAction.details:
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CommandDetailPage(commandId: command.id),
                            ),
                          );
                          break;
                        case _CommandCardMenuAction.edit:
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EditCommandPage(commandId: command.id),
                            ),
                          );
                          break;
                        case _CommandCardMenuAction.delete:
                          await _confirmAndDelete(
                            context: context,
                            commandProvider: commandProvider,
                            command: command,
                          );
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<_CommandCardMenuAction>(
                        value: _CommandCardMenuAction.details,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.info_outline_rounded),
                          title: Text('Voir le détail'),
                        ),
                      ),
                      PopupMenuItem<_CommandCardMenuAction>(
                        value: _CommandCardMenuAction.edit,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Modifier'),
                        ),
                      ),
                      PopupMenuItem<_CommandCardMenuAction>(
                        value: _CommandCardMenuAction.delete,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.delete_outline_rounded),
                          title: Text('Supprimer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (command.description.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  command.description.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              const SizedBox(height: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: DynamicProgressBar(
                  key: ValueKey<String>('progress-${command.progress}-${command.target}'),
                  progress: command.progress,
                  target: command.target,
                  accentTintColor: hasCustomAccent ? accentColor : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Fréquence: ${_frequencyLabel(command.frequency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (command.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: command.tags
                      .map(
                        (tag) => Chip(
                          label: Text('#$tag'),
                          visualDensity: VisualDensity.compact,
                          side: hasCustomAccent
                              ? BorderSide(
                                  color: accentColor.withValues(alpha: 0.55),
                                )
                              : null,
                          backgroundColor: hasCustomAccent
                              ? accentColor.withValues(alpha: 0.16)
                              : null,
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Réinitialiser',
                  color: iconAccent,
                  onPressed: () => commandProvider.resetProgress(command.id),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CommandCardMenuAction {
  details,
  edit,
  delete,
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

