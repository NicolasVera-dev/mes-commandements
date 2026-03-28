import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../utils/cycle_visual_style.dart';

class YearlyBar extends StatelessWidget {
  final int year;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;

  const YearlyBar({
    super.key,
    required this.year,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    if (!isCycleVisible(
      frequency: Frequency.yearly,
      cycleStartUtc: DateTime.utc(year, 1, 1),
      createdAtUtc: createdAtUtc,
    )) {
      return const SizedBox.shrink();
    }
    final key = '$year';
    final success = hasComplete(grouped[key] ?? const <CommandEvent>[]);
    final nowYear = DateTime.now().toUtc().year;
    final status = statusForCycle(
      isSuccess: success,
      isCurrent: key == currentKey,
      isPast: year < nowYear,
    );
    final style = styleForStatus(status, context);
    final textColor = accessibleForegroundColor(
      backgroundColor: style.backgroundColor,
      context: context,
    );
    return Semantics(
      label: 'Année $year : ${statusSemantics(status)}',
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: style.backgroundColor,
          border: Border.all(color: style.indicatorColor.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: style.indicatorColor),
            const SizedBox(width: 4),
            Icon(style.stateIcon, size: 12, color: textColor),
            const SizedBox(width: 6),
            Text(
              '$year',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
