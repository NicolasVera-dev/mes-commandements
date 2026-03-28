import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

class CycleSummary {
  final int success;
  final int failed;

  const CycleSummary({
    required this.success,
    required this.failed,
  });

  int get total => success + failed;
  int get completionRate => total == 0 ? 0 : ((success / total) * 100).round();
}

class BuildCycleSummaryUseCase {
  const BuildCycleSummaryUseCase();

  CycleSummary execute({
    required Frequency frequency,
    required DateTime anchorUtc,
    required Map<String, List<CommandEvent>> grouped,
    required String currentKey,
    required DateTime createdAtUtc,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final cycleKeys = _cycleKeysForPeriod(
      frequency: frequency,
      anchorUtc: anchorUtc.toUtc(),
      createdAtUtc: createdAtUtc.toUtc(),
    );

    var success = 0;
    var failed = 0;
    for (final key in cycleKeys) {
      final events = grouped[key] ?? const <CommandEvent>[];
      if (_hasComplete(events)) {
        success++;
        continue;
      }
      final isPast = switch (frequency) {
        Frequency.daily => DateTime.parse('${key}T00:00:00Z')
            .isBefore(DateTime.utc(now.year, now.month, now.day)),
        Frequency.weekly => key != currentKey && key.compareTo(currentKey) < 0,
        Frequency.monthly => key.compareTo(
            '${now.year}-${now.month.toString().padLeft(2, '0')}') < 0,
        Frequency.yearly => int.parse(key) < now.year,
      };
      if (isPast) failed++;
    }
    return CycleSummary(success: success, failed: failed);
  }

  List<String> _cycleKeysForPeriod({
    required Frequency frequency,
    required DateTime anchorUtc,
    required DateTime createdAtUtc,
  }) {
    final keys = <String>[];
    switch (frequency) {
      case Frequency.daily:
        final start = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
        final end = anchorUtc.month == 12
            ? DateTime.utc(anchorUtc.year + 1, 1, 1)
            : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
        var d = start;
        while (d.isBefore(end)) {
          if (_isCycleVisible(frequency: frequency, cycleStartUtc: d, createdAtUtc: createdAtUtc)) {
            keys.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
          }
          d = d.add(const Duration(days: 1));
        }
        break;
      case Frequency.weekly:
        final monthStart = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
        final monthEnd = anchorUtc.month == 12
            ? DateTime.utc(anchorUtc.year + 1, 1, 1)
            : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
        var cursor = monthStart;
        while (cursor.isBefore(monthEnd)) {
          final weekStart =
              CycleKeyGenerator.cycleStartUtc(Frequency.weekly, cursor);
          if (_isCycleVisible(frequency: frequency, cycleStartUtc: weekStart, createdAtUtc: createdAtUtc)) {
            final key = CycleKeyGenerator.forFrequency(
              frequency: Frequency.weekly,
              atUtc: cursor,
            );
            if (!keys.contains(key)) keys.add(key);
          }
          cursor = cursor.add(const Duration(days: 7));
        }
        break;
      case Frequency.monthly:
        for (var m = 1; m <= 12; m++) {
          final monthStart = DateTime.utc(anchorUtc.year, m, 1);
          if (_isCycleVisible(frequency: frequency, cycleStartUtc: monthStart, createdAtUtc: createdAtUtc)) {
            keys.add('${anchorUtc.year}-${m.toString().padLeft(2, '0')}');
          }
        }
        break;
      case Frequency.yearly:
        if (_isCycleVisible(
          frequency: frequency,
          cycleStartUtc: DateTime.utc(anchorUtc.year, 1, 1),
          createdAtUtc: createdAtUtc,
        )) {
          keys.add('${anchorUtc.year}');
        }
        break;
    }
    return keys;
  }

  bool _isCycleVisible({
    required Frequency frequency,
    required DateTime cycleStartUtc,
    required DateTime createdAtUtc,
  }) {
    final firstVisibleCycleStart =
        CycleKeyGenerator.cycleStartUtc(frequency, createdAtUtc.toUtc());
    return !cycleStartUtc.toUtc().isBefore(firstVisibleCycleStart);
  }

  bool _hasComplete(List<CommandEvent> events) {
    return events.any((e) => e.type == CommandEventType.complete);
  }
}
