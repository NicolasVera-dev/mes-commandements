import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../domain/entities/journal_day.dart';
import '../state/journal_provider.dart';

class JournalWeekOverview extends StatelessWidget {
  final JournalDay today;
  final ValueChanged<JournalDay> onSelectDay;
  const JournalWeekOverview({
    super.key,
    required this.today,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();
    final strings = context.l10n;
    final dates = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(strings.journalWeek, style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(7, (index) {
            final day = today.add(index - 6);
            final score = provider.summary(day).score;
            final label = score == null
                ? strings.journalWeekEmpty(dates.formatMediumDate(day.date))
                : strings.journalWeekDay(
                    dates.formatMediumDate(day.date),
                    score,
                  );
            return Expanded(
              child: Semantics(
                label: label,
                button: true,
                child: Tooltip(
                  message: label,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelectDay(day),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 4,
                      ),
                      child: Column(
                        children: [
                          Text(
                            dates.narrowWeekdays[day.date.weekday % 7],
                            style: theme.textTheme.labelSmall,
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: (score ?? 0) / 100,
                            minHeight: 5,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            score == null ? '—' : '$score%',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
