import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/command.dart';
import '../pages/edit_command_page.dart';
import '../state/command_provider.dart';

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
  late double _fromRatio;
  late double _toRatio;

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
  void initState() {
    super.initState();
    final ratio = _progressRatio(widget.command);
    _fromRatio = ratio;
    _toRatio = ratio;
  }

  @override
  void didUpdateWidget(covariant CommandCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldRatio = _progressRatio(oldWidget.command);
    final newRatio = _progressRatio(widget.command);
    final oldCompleted = oldWidget.command.isCompleted();
    final newCompleted = widget.command.isCompleted();

    if (oldCompleted != newCompleted && newCompleted) {
      HapticFeedback.mediumImpact();
    }

    if (oldRatio == newRatio && oldCompleted == newCompleted) return;

    setState(() {
      _fromRatio = oldRatio;
      _toRatio = newRatio;
    });
  }

  double _progressRatio(Command command) {
    if (command.target <= 0) return 0.0;
    return command.progress / command.target;
  }

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.read<CommandProvider>();
    final command = widget.command;
    final searchQuery = context.select<CommandProvider, String>(
      (p) => p.searchQuery,
    );
    final isCompleted = command.isCompleted();
    final progressColor = isCompleted
        ? Colors.greenAccent.shade200
        : Theme.of(context).colorScheme.primary;

    final borderColor = isCompleted
        ? Colors.greenAccent.shade200.withValues(alpha: 0.55)
        : Colors.transparent;

    return Material(
      type: MaterialType.card,
      elevation: isCompleted ? 4 : 2,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          if (isCompleted) return;
          commandProvider.incrementProgress(command.id);
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.12)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
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
                          return Text(command.title, style: baseStyle);
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

                        return RichText(
                          text: TextSpan(children: spans),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => EditCommandPage(commandId: command.id),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
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
                                  backgroundColor:
                                      Theme.of(context).colorScheme.errorContainer,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onErrorContainer,
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
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  '${command.progress} / ${command.target}',
                  key: ValueKey<int>(command.progress),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 10),
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                tween: Tween<double>(begin: _fromRatio, end: _toRatio),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value.clamp(0.0, 1.0),
                    minHeight: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                'Fréquence: ${_frequencyLabel(command.frequency)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Réinitialiser',
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

