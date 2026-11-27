import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/localization/localization.dart';
import '../../domain/services/journal_day_summary.dart';

class JournalProgressCard extends StatelessWidget {
  final JournalDaySummary summary;
  final bool isFuture;
  const JournalProgressCard({
    super.key,
    required this.summary,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = context.l10n;
    final score = summary.score;
    final allDone = score == 100;
    final success =
        theme.extension<AppSemanticColors>()?.completedCardIcon ??
        theme.colorScheme.primary;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allDone && !isFuture
                      ? Icons.task_alt_rounded
                      : Icons.checklist_rounded,
                  color: allDone && !isFuture
                      ? success
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isFuture
                        ? strings.journalFutureScore
                        : strings.journalAccomplishments,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (!isFuture)
                  IconButton(
                    tooltip: strings.journalScoreHelp,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(strings.journalAccomplishments),
                        content: Text(strings.journalScoreHelp),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              MaterialLocalizations.of(context)
                                  .closeButtonLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 19),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (!isFuture)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    score == null ? '—' : '$score %',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: allDone ? success : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      score == null
                          ? strings.journalNoScore
                          : strings.journalCompletedCount(
                              summary.completed.length,
                              summary.tasks.length,
                            ),
                    ),
                  ),
                ],
              ),
            if (score != null && !isFuture)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Semantics(
                  label: strings.journalCompletedCount(
                    summary.completed.length,
                    summary.tasks.length,
                  ),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: score / 100),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 350),
                    builder: (_, value, child) => LinearProgressIndicator(
                      value: value,
                      borderRadius: BorderRadius.circular(6),
                      minHeight: 6,
                      color: allDone ? success : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            Text(
              isFuture
                  ? strings.journalFutureHint
                  : allDone
                  ? strings.journalCelebrate
                  : summary.completed.isEmpty
                  ? strings.journalStart
                  : strings.journalProgress,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
