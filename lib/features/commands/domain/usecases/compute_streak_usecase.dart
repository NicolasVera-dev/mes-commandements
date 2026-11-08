import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

enum StreakBadge {
  none,
  recovered,
  goodStart,
  inRhythm,
  solidStreak,
  consistent,
  momentum,
  milestone,
  established,
  legendary,
  missedOccasion(isNegative: true),
  setback(isNegative: true),
  findRhythm(isNegative: true),
  slowingDown(isNegative: true),
  adjustGoal(isNegative: true),
  smallStep(isNegative: true),
  freshStart(isNegative: true),
  rethinkDirection(isNegative: true);

  const StreakBadge({this.isNegative = false});

  final bool isNegative;
}

class StreakResult {
  final StreakBadge badge;
  final int count;

  const StreakResult({required this.badge, required this.count});
}

class ComputeStreakUseCase {
  const ComputeStreakUseCase();

  static const _noBadge = StreakResult(badge: StreakBadge.none, count: 0);
  static const _positiveBadges = [
    StreakBadge.goodStart,
    StreakBadge.inRhythm,
    StreakBadge.solidStreak,
    StreakBadge.consistent,
    StreakBadge.momentum,
    StreakBadge.milestone,
    StreakBadge.established,
    StreakBadge.legendary,
  ];
  static const _negativeBadges = [
    StreakBadge.missedOccasion,
    StreakBadge.setback,
    StreakBadge.findRhythm,
    StreakBadge.slowingDown,
    StreakBadge.adjustGoal,
    StreakBadge.smallStep,
    StreakBadge.freshStart,
    StreakBadge.rethinkDirection,
  ];

  StreakResult execute({
    required Command command,
    required Map<String, List<CommandEvent>> grouped,
    required DateTime createdAtUtc,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (now.isBefore(createdAtUtc)) return _noBadge;

    final frequency = command.frequency;
    final currentStart = CycleKeyGenerator.cycleStartUtc(frequency, now);
    final firstStart = CycleKeyGenerator.cycleStartUtc(frequency, createdAtUtc);
    bool hasComplete(DateTime cycle) =>
        grouped[command.cycleKeyAt(cycle)]?.any(
          (event) => event.type == CommandEventType.complete,
        ) ??
        false;

    final progressCycle = command.lastResetAt ?? createdAtUtc;
    final currentComplete =
        command.isActiveOnDayUtc(now) &&
        (hasComplete(currentStart) ||
            (command.isCompleted() && !progressCycle.isBefore(currentStart)));

    bool? pastSuccess;
    var pastCount = 0;
    for (
      var cycle = _previousCycle(frequency, currentStart);
      !cycle.isBefore(firstStart);
      cycle = _previousCycle(frequency, cycle)
    ) {
      if (!command.isActiveOnDayUtc(cycle)) continue;
      final success = hasComplete(cycle);
      pastSuccess ??= success;
      if (success != pastSuccess) break;
      pastCount++;
    }

    if (currentComplete && pastSuccess == false) {
      return StreakResult(badge: StreakBadge.recovered, count: pastCount);
    }
    if (pastSuccess == false) {
      final thresholds = switch (frequency) {
        Frequency.daily => const [1, 2, 3, 5, 7, 10, 14, 21],
        Frequency.weekly => const [1, 2, 3, 4, 5, 6, 8, 12],
        Frequency.monthly => const [1, 2, 3, 4, 5, 6, 9, 12],
        Frequency.yearly => const [1, 2, 3, 4, 5, 6, 7, 8],
      };
      return _resultFor(pastCount, thresholds, _negativeBadges);
    }

    final thresholds = switch (frequency) {
      Frequency.daily => const [2, 3, 5, 7, 14, 30, 60, 100],
      Frequency.weekly => const [2, 3, 4, 6, 8, 12, 26, 52],
      Frequency.monthly => const [2, 3, 4, 6, 9, 12, 18, 24],
      Frequency.yearly => const [2, 3, 4, 5, 6, 8, 10, 15],
    };
    final count = pastCount + (currentComplete ? 1 : 0);
    return _resultFor(count, thresholds, _positiveBadges);
  }

  StreakResult _resultFor(
    int count,
    List<int> thresholds,
    List<StreakBadge> badges,
  ) {
    final index = thresholds.lastIndexWhere((threshold) => count >= threshold);
    if (index < 0) return _noBadge;
    return StreakResult(badge: badges[index], count: count);
  }

  DateTime _previousCycle(Frequency frequency, DateTime start) {
    return switch (frequency) {
      Frequency.daily => start.subtract(const Duration(days: 1)),
      Frequency.weekly => start.subtract(const Duration(days: 7)),
      Frequency.monthly => DateTime.utc(start.year, start.month - 1),
      Frequency.yearly => DateTime.utc(start.year - 1),
    };
  }
}
