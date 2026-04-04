import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/command_card_display_mode.dart';
import '../../../../app/command_card_layout_service.dart';
import '../../domain/entities/resistance.dart';
import '../../domain/usecases/compute_resistance_streak_usecase.dart';
import '../pages/edit_resistance_page.dart';
import '../pages/resistance_detail_page.dart';
import '../state/resistance_provider.dart';
import '../utils/resistance_streak_color.dart';
import 'resistance_relapse_dialog.dart';

List<TextSpan> _titleHighlightSpans({
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

class ResistanceCard extends StatelessWidget {
  final Resistance resistance;

  const ResistanceCard({
    super.key,
    required this.resistance,
  });

  static const _streakUseCase = ComputeResistanceStreakUseCase();

  Future<void> _onRelapse(BuildContext context) async {
    final streak = _streakUseCase.execute(
      resistance: resistance,
      nowUtc: DateTime.now().toUtc(),
    );
    final note = await showResistanceRelapseDialog(
      context: context,
      resistanceTitle: resistance.title,
      currentStreakDays: streak,
    );
    if (!context.mounted || note == null) return;
    await context.read<ResistanceProvider>().recordRelapse(
          resistanceId: resistance.id,
          note: note.isEmpty ? null : note,
        );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la résistance ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.errorContainer,
              foregroundColor: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ResistanceProvider>().deleteResistance(resistance.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semanticColors = Theme.of(context).extension<AppSemanticColors>();
    final compact = context.watch<CommandCardLayoutService>().displayMode ==
        CommandCardDisplayMode.compact;
    final searchQuery = context.select<ResistanceProvider, String>(
      (p) => p.searchQuery,
    );

    final streak = _streakUseCase.execute(
      resistance: resistance,
      nowUtc: DateTime.now().toUtc(),
    );
    final streakColor =
        resistanceStreakColor(streakDays: streak, context: context);
    final hasAccent = resistance.accentColorValue != null;
    final accent = hasAccent ? Color(resistance.accentColorValue!) : scheme.primary;

    final background = hasAccent
        ? Color.alphaBlend(
            accent.withValues(alpha: 0.08),
            scheme.surfaceContainerHighest,
          )
        : scheme.surfaceContainerHighest;

    final cardRadius = compact ? 12.0 : 16.0;
    final emojiBox = compact ? 28.0 : 34.0;
    final emojiFontSize = compact ? 15.0 : 18.0;
    final titleMaxLines = compact ? 1 : 2;
    final innerPadding = compact ? 8.0 : 12.0;
    final gapAfterHeader = compact ? 8.0 : 14.0;
    final gapBeforeButton = compact ? 8.0 : 14.0;

    final baseTitleStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleMedium;

    return Material(
      type: MaterialType.card,
      elevation: 2,
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(cardRadius),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ResistanceDetailPage(resistanceId: resistance.id),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: hasAccent
                  ? accent.withValues(alpha: 0.45)
                  : scheme.outlineVariant.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(cardRadius),
          ),
          padding: EdgeInsets.all(innerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    width: emojiBox,
                    height: emojiBox,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Hero(
                      tag: 'resistance-emoji-${resistance.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          resistance.emoji,
                          style: TextStyle(fontSize: emojiFontSize),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 10),
                  Expanded(
                    child: baseTitleStyle == null
                        ? Text(resistance.title)
                        : Builder(
                            builder: (context) {
                              final q = searchQuery.trim();
                              if (q.isEmpty) {
                                return Text(
                                  resistance.title,
                                  style: baseTitleStyle,
                                  maxLines: titleMaxLines,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              final highlightStyle = baseTitleStyle.copyWith(
                                backgroundColor: scheme.primary
                                    .withValues(alpha: 0.22),
                                fontWeight: FontWeight.w600,
                              );
                              return RichText(
                                text: TextSpan(
                                  children: _titleHighlightSpans(
                                    text: resistance.title,
                                    query: q,
                                    baseStyle: baseTitleStyle,
                                    highlightStyle: highlightStyle,
                                  ),
                                ),
                                maxLines: titleMaxLines,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded),
                    tooltip: 'Actions',
                    style: IconButton.styleFrom(
                      minimumSize: Size(compact ? 40 : 44, compact ? 40 : 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: compact
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => EditResistancePage(
                                resistanceId: resistance.id,
                              ),
                            ),
                          );
                        case 'delete':
                          _confirmDelete(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifier'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Supprimer',
                          style: TextStyle(
                            color: semanticColors?.failedIndicator ??
                                scheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: gapAfterHeader),
              Center(
                child: Column(
                  children: [
                    Text(
                      '$streak',
                      style: (compact
                              ? Theme.of(context).textTheme.headlineLarge
                              : Theme.of(context).textTheme.displaySmall)
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: streakColor,
                            height: 1.05,
                          ),
                    ),
                    Text(
                      streak == 1
                          ? 'jour sans craquer'
                          : 'jours sans craquer',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: compact ? 12 : null,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: gapBeforeButton),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: scheme.error,
                    foregroundColor: scheme.onError,
                    elevation: compact ? 1 : 2,
                    shadowColor: scheme.error.withValues(alpha: 0.45),
                    visualDensity: compact
                        ? VisualDensity.compact
                        : VisualDensity.standard,
                    padding: compact
                        ? const EdgeInsets.symmetric(vertical: 10, horizontal: 16)
                        : const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  ),
                  onPressed: () => _onRelapse(context),
                  child: Text(
                    'J’ai craqué 😔',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                      fontSize: compact ? 13.5 : 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
