import '../../domain/entities/command.dart';
import '../../domain/services/cycle_key_generator.dart';
import 'cycle_visual_style.dart';

/// Cycle keys affichés pour la période courante du détail (aligné sur les visualisations).
Set<String> cycleKeysForDetailPeriod({
  required Frequency frequency,
  required DateTime anchorUtc,
  required DateTime createdAtUtc,
}) {
  final keys = <String>{};
  if (frequency == Frequency.daily) {
    final start = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final end = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    final days = end.difference(start).inDays;
    for (var i = 0; i < days; i++) {
      final day = DateTime.utc(anchorUtc.year, anchorUtc.month, i + 1);
      if (!isCycleVisible(
        frequency: Frequency.daily,
        cycleStartUtc: day,
        createdAtUtc: createdAtUtc,
      )) {
        continue;
      }
      keys.add(
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      );
    }
  } else if (frequency == Frequency.weekly) {
    final monthStart = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final monthEnd = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    var cursor = monthStart;
    while (cursor.isBefore(monthEnd)) {
      final weekKey = CycleKeyGenerator.forFrequency(
        frequency: Frequency.weekly,
        atUtc: cursor,
      );
      final weekStart = _weekStartFromCycleKey(weekKey);
      if (isCycleVisible(
        frequency: Frequency.weekly,
        cycleStartUtc: weekStart,
        createdAtUtc: createdAtUtc,
      )) {
        keys.add(weekKey);
      }
      cursor = cursor.add(const Duration(days: 7));
    }
  } else if (frequency == Frequency.monthly) {
    final year = anchorUtc.year;
    for (var month = 1; month <= 12; month++) {
      final cycleStart = DateTime.utc(year, month, 1);
      if (!isCycleVisible(
        frequency: Frequency.monthly,
        cycleStartUtc: cycleStart,
        createdAtUtc: createdAtUtc,
      )) {
        continue;
      }
      keys.add('$year-${month.toString().padLeft(2, '0')}');
    }
  } else if (frequency == Frequency.yearly) {
    final year = anchorUtc.year;
    if (isCycleVisible(
      frequency: Frequency.yearly,
      cycleStartUtc: DateTime.utc(year, 1, 1),
      createdAtUtc: createdAtUtc,
    )) {
      keys.add('$year');
    }
  }
  return keys;
}

DateTime _weekStartFromCycleKey(String cycleKey) {
  final match = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
  if (match == null) {
    return DateTime.utc(1970, 1, 1);
  }
  final y = int.parse(match.group(1)!);
  final week = int.parse(match.group(2)!);
  final jan4 = DateTime.utc(y, 1, 4);
  final mondayWeek1 = jan4.subtract(Duration(days: jan4.weekday - DateTime.monday));
  return mondayWeek1.add(Duration(days: (week - 1) * 7));
}
