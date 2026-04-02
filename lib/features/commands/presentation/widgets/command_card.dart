import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/command.dart';
import '../../../../app/app_theme.dart';
import '../../../../app/command_card_display_mode.dart';
import '../../../../app/command_card_layout_service.dart';
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
    final compact = context.watch<CommandCardLayoutService>().displayMode ==
        CommandCardDisplayMode.compact;
    final searchQuery = context.select<CommandProvider, String>(
      (p) => p.searchQuery,
    );
    final isCompleted = command.isCompleted();
    final scheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final hasCustomAccent = command.accentColorValue != null;
    final accentColor = command.accentColorValue == null
        ? Theme.of(context).colorScheme.primary
        : Color(command.accentColorValue!);

    final borderColor = isCompleted
        ? (semanticColors?.completedCardBorder ?? scheme.primary)
        : (hasCustomAccent
            ? accentColor.withValues(alpha: 0.5)
            : Colors.transparent);
    final cardBackgroundColor = isCompleted
        ? (semanticColors?.completedCardBackground ??
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.12),
              scheme.surfaceContainerHighest,
            ))
        : hasCustomAccent
            ? Color.alphaBlend(
                accentColor.withValues(alpha: 0.08),
                Theme.of(context).colorScheme.surfaceContainerHighest,
              )
            : Theme.of(context).colorScheme.surfaceContainerHighest;
    final iconAccent = hasCustomAccent ? accentColor : null;

    final cardRadius = compact ? 12.0 : 16.0;
    final emojiBox = compact ? 28.0 : 34.0;
    final emojiFontSize = compact ? 15.0 : 18.0;
    final titleMaxLines = compact ? 1 : 2;

    return Material(
      type: MaterialType.card,
      elevation: isCompleted ? 4 : 2,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(cardRadius),
      child: IncrementAnimationOverlay(
        enabled: !isCompleted,
        onTap: () {
          commandProvider.incrementProgress(command.id);
        },
        borderRadius: BorderRadius.circular(cardRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: cardBackgroundColor,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          padding: EdgeInsets.all(compact ? 8 : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final baseStyle = compact
                            ? Theme.of(context).textTheme.titleSmall
                            : Theme.of(context).textTheme.titleMedium;
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
                                width: emojiBox,
                                height: emojiBox,
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
                                      style: TextStyle(fontSize: emojiFontSize),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  command.title,
                                  style: baseStyle,
                                  maxLines: titleMaxLines,
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
                              width: emojiBox,
                              height: emojiBox,
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
                                    style: TextStyle(fontSize: emojiFontSize),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(children: spans),
                                maxLines: titleMaxLines,
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
                            size: compact ? 22 : 24,
                            color: semanticColors?.completedCardIcon ?? scheme.primary,
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
                      minimumSize: Size(compact ? 40 : 44, compact ? 40 : 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity:
                          compact ? VisualDensity.compact : VisualDensity.standard,
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
                SizedBox(height: compact ? 2 : 4),
                Text(
                  command.description.trim(),
                  maxLines: compact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: (compact
                          ? Theme.of(context).textTheme.bodySmall
                          : Theme.of(context).textTheme.bodyMedium)
                      ?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              SizedBox(height: compact ? 6 : 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: DynamicProgressBar(
                  key: ValueKey<String>(
                    'progress-${command.progress}-${command.target}-$compact',
                  ),
                  progress: command.progress,
                  target: command.target,
                  accentTintColor: hasCustomAccent ? accentColor : null,
                  compact: compact,
                ),
              ),
              if (!compact) ...[
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
              ] else ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _frequencyLabelCompact(command.frequency),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Réinitialiser',
                      color: iconAccent,
                      visualDensity: VisualDensity.compact,
                      style: IconButton.styleFrom(
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      onPressed: () => commandProvider.resetProgress(command.id),
                      icon: const Icon(Icons.refresh, size: 20),
                    ),
                  ],
                ),
                if (command.tags.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _CompactTagsRow(
                    tags: command.tags,
                    accentColor: accentColor,
                    hasCustomAccent: hasCustomAccent,
                  ),
                ],
              ],
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

/// Libellés courts pour la ligne méta en mode compact.
String _frequencyLabelCompact(Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return 'Quotid.';
    case Frequency.weekly:
      return 'Hebd.';
    case Frequency.monthly:
      return 'Mens.';
    case Frequency.yearly:
      return 'Ann.';
  }
}

class _CompactTagsRow extends StatelessWidget {
  const _CompactTagsRow({
    required this.tags,
    required this.accentColor,
    required this.hasCustomAccent,
  });

  final List<String> tags;
  final Color accentColor;
  final bool hasCustomAccent;

  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context) {
    final visible = tags.take(_maxVisible).toList();
    final extra = tags.length - visible.length;

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ...visible.map(
          (tag) => Chip(
            label: Text(
              '#$tag',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            labelPadding: EdgeInsets.zero,
            side: hasCustomAccent
                ? BorderSide(color: accentColor.withValues(alpha: 0.55))
                : null,
            backgroundColor: hasCustomAccent
                ? accentColor.withValues(alpha: 0.16)
                : null,
          ),
        ),
        if (extra > 0)
          Chip(
            label: Text(
              '+$extra',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const EdgeInsets.symmetric(horizontal: 6),
          ),
      ],
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

