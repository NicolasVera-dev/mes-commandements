import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../../domain/entities/cycle_note.dart';
import '../../../domain/services/cycle_key_generator.dart';
import '../../utils/cycle_visual_style.dart';
import '../cycle_note_bottom_sheet.dart';
import '../cycle_note_indicator.dart';

class WeeklyList extends StatelessWidget {
  final DateTime anchorUtc;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final int target;
  final DateTime createdAtUtc;
  final String commandId;
  final Map<String, CycleNote> notes;

  const WeeklyList({
    super.key,
    required this.anchorUtc,
    required this.grouped,
    required this.currentKey,
    required this.target,
    required this.createdAtUtc,
    required this.commandId,
    this.notes = const <String, CycleNote>{},
  });

  void _openNote(BuildContext context, String cycleKey) {
    showCycleNoteEditorSheet(
      context,
      commandId: commandId,
      cycleKey: cycleKey,
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = <String>[];
    final monthStart = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final monthEnd = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    final currentWeekStart =
        CycleKeyGenerator.cycleStartUtc(Frequency.weekly, DateTime.now().toUtc());

    var cursor = monthStart;
    while (cursor.isBefore(monthEnd)) {
      final weekKey = CycleKeyGenerator.forFrequency(
        frequency: Frequency.weekly,
        atUtc: cursor,
      );
      if (!weeks.contains(weekKey)) weeks.add(weekKey);
      cursor = cursor.add(const Duration(days: 7));
    }

    return Column(
      children: weeks.map((weekKey) {
        final weekStart = _weekStartFromCycleKey(weekKey);
        if (!isCycleVisible(
          frequency: Frequency.weekly,
          cycleStartUtc: weekStart,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final events = grouped[weekKey] ?? const <CommandEvent>[];
        final increments = events.where((e) => e.type == CommandEventType.increment).length;
        final progress = events.isEmpty
            ? 0
            : events.map((e) => e.progressAfterAction).reduce((a, b) => a > b ? a : b);
        final progressRatio = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
        final success = hasComplete(events);
        final status = statusForCycle(
          isSuccess: success,
          isCurrent: weekKey == currentKey,
          isPast: weekStart.isBefore(currentWeekStart),
        );
        final style = styleForStatus(status, context);
        final textColor = accessibleForegroundColor(
          backgroundColor: style.backgroundColor,
          context: context,
        );
        final weekNumber = _weekNumberFromCycleKey(weekKey);
        final hasNote = notes.containsKey(weekKey);
        final semanticsNote = hasNote ? ', note enregistrée' : '';

        return Semantics(
          label:
              'Semaine $weekNumber : ${statusSemantics(status)}$semanticsNote. Appuyez pour ajouter ou modifier une note.',
          button: true,
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: style.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: style.indicatorColor.withValues(alpha: 0.55)),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _openNote(context, weekKey),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          weekKey,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: textColor,
                              ),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: progressRatio,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColorForRatio(context, progressRatio),
                          ),
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHigh,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '$progress/$target',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Wrap(
                              spacing: 4,
                              children: List.generate(
                                increments.clamp(0, 20),
                                (_) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Icon(Icons.circle, size: 12, color: style.indicatorColor),
                            const SizedBox(width: 4),
                            Icon(style.stateIcon, size: 14, color: textColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: CycleNoteIndicator(
                      hasNote: hasNote,
                      onPressed: () => _openNote(context, weekKey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

DateTime _weekStartFromCycleKey(String cycleKey) {
  final match = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
  if (match == null) {
    return DateTime.utc(1970, 1, 1);
  }
  final year = int.parse(match.group(1)!);
  final week = int.parse(match.group(2)!);
  return _isoWeekStartUtc(year, week);
}

DateTime _isoWeekStartUtc(int year, int week) {
  final jan4 = DateTime.utc(year, 1, 4);
  final mondayWeek1 = jan4.subtract(Duration(days: jan4.weekday - DateTime.monday));
  return mondayWeek1.add(Duration(days: (week - 1) * 7));
}

int _weekNumberFromCycleKey(String cycleKey) {
  final match = RegExp(r'^\d{4}-[SW](\d{2})$').firstMatch(cycleKey);
  if (match == null) return 0;
  return int.parse(match.group(1)!);
}
