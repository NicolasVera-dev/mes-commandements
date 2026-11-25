import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/localization/localization.dart';
import '../../domain/entities/journal_day.dart';
import '../../domain/entities/journal_task.dart';

enum JournalTaskAction { edit, reschedule, delete }

class JournalTaskCard extends StatelessWidget {
  final JournalTask task;
  final JournalDay day;
  final bool isToday;
  final bool readOnly;
  final bool busy;
  final ValueChanged<bool> onToggle;
  final ValueChanged<JournalTaskAction> onAction;

  const JournalTaskCard({
    super.key,
    required this.task,
    required this.day,
    required this.isToday,
    required this.readOnly,
    required this.busy,
    required this.onToggle,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>();
    final strings = context.l10n;
    final done = task.completedOn(day);
    final late = task.lateDaysOn(day);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 0,
      color: done
          ? semantic?.completedCardBackground
          : theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: done
            ? BorderSide(
                color:
                    semantic?.completedCardBorder ?? theme.colorScheme.primary,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: done,
              onChanged: isToday && !busy && !readOnly
                  ? (value) => onToggle(value!)
                  : null,
              activeColor: semantic?.completedCardIcon,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? semantic?.completedCardIcon : null,
                    ),
                  ),
                  if (task.priority)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              strings.journalPriority,
                              style: theme.textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (done)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        isToday
                            ? strings.journalCompletedToday
                            : strings.journalCompletedDay,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: semantic?.completedCardIcon,
                        ),
                      ),
                    )
                  else if (late > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        strings.journalLate(late),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (!done && late > 0)
                    Text(
                      strings.journalOriginalDate(
                        MaterialLocalizations.of(context)
                            .formatMediumDate(task.originalDay.date),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (!readOnly)
              PopupMenuButton<JournalTaskAction>(
                enabled: !busy,
                tooltip: strings.journalTaskActions,
                onSelected: onAction,
                itemBuilder: (_) => [
                  if (!done)
                    PopupMenuItem(
                      value: JournalTaskAction.edit,
                      child: Text(strings.journalEditTask),
                    ),
                  if (!done)
                    PopupMenuItem(
                      value: JournalTaskAction.reschedule,
                      child: Text(strings.journalReschedule),
                    ),
                  PopupMenuItem(
                    value: JournalTaskAction.delete,
                    child: Text(strings.journalDeleteTask),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
