import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../utils/cycle_visual_style.dart';

class MonthlyGrid extends StatelessWidget {
  final int year;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;

  const MonthlyGrid({
    super.key,
    required this.year,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final cycleStart = DateTime.utc(year, month, 1);
        if (!isCycleVisible(
          frequency: Frequency.monthly,
          cycleStartUtc: cycleStart,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final key = '$year-${month.toString().padLeft(2, '0')}';
        final success = hasComplete(grouped[key] ?? const <CommandEvent>[]);
        final isCurrent = key == currentKey;
        final isPast = DateTime.utc(year, month, 1).isBefore(DateTime.utc(now.year, now.month, 1));
        final status = statusForCycle(
          isSuccess: success,
          isCurrent: isCurrent,
          isPast: isPast,
        );
        final style = styleForStatus(status, context);
        final textColor = accessibleForegroundColor(
          backgroundColor: style.backgroundColor,
          context: context,
        );
        return Semantics(
          label: '${monthLabel(month)} $year : ${statusSemantics(status)}',
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.backgroundColor,
              border: Border.all(color: style.indicatorColor.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(style.stateIcon, size: 12, color: textColor),
                const SizedBox(width: 4),
                Text(
                  month.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
