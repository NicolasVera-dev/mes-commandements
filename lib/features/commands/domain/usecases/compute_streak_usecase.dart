import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

enum StreakBadge {
  none,
  recoveredToday,
  /// Succès palier 1 (seuils selon fréquence, ex. ≥3 jours).
  success1,
  success2,
  success3,
  success4,
  /// Échecs consécutifs — quotidien (libellés « jours »).
  failDaily,
  /// Échecs consécutifs — hebdo / mensuel / annuel (libellés adaptés).
  failOther,
}

class StreakResult {
  final StreakBadge badge;
  final int count;

  const StreakResult({
    required this.badge,
    required this.count,
  });
}

/// Calcule le badge de série (cycles passés uniquement, hors cycle courant non terminé).
class ComputeStreakUseCase {
  const ComputeStreakUseCase();

  StreakResult execute({
    required Command command,
    required Map<String, List<CommandEvent>> grouped,
    required DateTime createdAtUtc,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final pastKeys = _pastCycleKeysNewestFirst(
      frequency: command.frequency,
      createdAtUtc: createdAtUtc.toUtc(),
      nowUtc: now,
    );

    bool hasComplete(List<CommandEvent>? events) =>
        (events ?? const <CommandEvent>[]).any(
          (e) => e.type == CommandEventType.complete,
        );

    final currentComplete =
        hasComplete(grouped[command.cycleKeyAt(now)]) || command.isCompleted();

    var goodRun = 0;
    for (final key in pastKeys) {
      if (!grouped.containsKey(key)) {
        break;
      }
      if (hasComplete(grouped[key])) {
        goodRun++;
      } else {
        break;
      }
    }

    var badRun = 0;
    for (final key in pastKeys) {
      if (!grouped.containsKey(key)) {
        break;
      }
      if (!hasComplete(grouped[key])) {
        badRun++;
      } else {
        break;
      }
    }

    if (currentComplete && goodRun == 0 && badRun >= 1) {
      return StreakResult(badge: StreakBadge.recoveredToday, count: badRun);
    }

    final successBadge = _successBadge(command.frequency, goodRun);
    if (successBadge != null) {
      return StreakResult(badge: successBadge, count: goodRun);
    }

    if (!currentComplete && badRun >= 3) {
      final fail = command.frequency == Frequency.daily
          ? StreakBadge.failDaily
          : StreakBadge.failOther;
      return StreakResult(badge: fail, count: badRun);
    }

    return const StreakResult(badge: StreakBadge.none, count: 0);
  }

  /// Retourne le palier de succès affichable, ou `null` si [goodRun] &lt; premier seuil.
  StreakBadge? _successBadge(Frequency frequency, int goodRun) {
    switch (frequency) {
      case Frequency.daily:
      case Frequency.weekly:
        if (goodRun < 3) return null;
        if (goodRun >= 30) return StreakBadge.success4;
        if (goodRun >= 10) return StreakBadge.success3;
        if (goodRun >= 6) return StreakBadge.success2;
        return StreakBadge.success1;
      case Frequency.monthly:
        if (goodRun < 3) return null;
        if (goodRun >= 24) return StreakBadge.success4;
        if (goodRun >= 10) return StreakBadge.success3;
        if (goodRun >= 6) return StreakBadge.success2;
        return StreakBadge.success1;
      case Frequency.yearly:
        if (goodRun < 3) return null;
        if (goodRun >= 20) return StreakBadge.success4;
        if (goodRun >= 10) return StreakBadge.success3;
        if (goodRun >= 5) return StreakBadge.success2;
        return StreakBadge.success1;
    }
  }

  List<String> _pastCycleKeysNewestFirst({
    required Frequency frequency,
    required DateTime createdAtUtc,
    required DateTime nowUtc,
  }) {
    final firstVisibleStart =
        CycleKeyGenerator.cycleStartUtc(frequency, createdAtUtc.toUtc());

    switch (frequency) {
      case Frequency.daily:
        final currentDayStart =
            DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
        var d = currentDayStart.subtract(const Duration(days: 1));
        final keys = <String>[];
        while (!d.isBefore(firstVisibleStart)) {
          keys.add(
            CycleKeyGenerator.forFrequency(
              frequency: Frequency.daily,
              atUtc: d,
            ),
          );
          d = d.subtract(const Duration(days: 1));
        }
        return keys;
      case Frequency.weekly:
        final currentWeekStart =
            CycleKeyGenerator.cycleStartUtc(Frequency.weekly, nowUtc);
        var w = currentWeekStart.subtract(const Duration(days: 7));
        final keys = <String>[];
        while (!w.isBefore(firstVisibleStart)) {
          keys.add(
            CycleKeyGenerator.forFrequency(
              frequency: Frequency.weekly,
              atUtc: w,
            ),
          );
          w = w.subtract(const Duration(days: 7));
        }
        return keys;
      case Frequency.monthly:
        final cursor = DateTime.utc(nowUtc.year, nowUtc.month, 1);
        var lastPast = cursor.month == 1
            ? DateTime.utc(cursor.year - 1, 12, 1)
            : DateTime.utc(cursor.year, cursor.month - 1, 1);
        final keys = <String>[];
        while (!lastPast.isBefore(firstVisibleStart)) {
          keys.add(
            CycleKeyGenerator.forFrequency(
              frequency: Frequency.monthly,
              atUtc: lastPast,
            ),
          );
          lastPast = lastPast.month == 1
              ? DateTime.utc(lastPast.year - 1, 12, 1)
              : DateTime.utc(lastPast.year, lastPast.month - 1, 1);
        }
        return keys;
      case Frequency.yearly:
        final keys = <String>[];
        for (var y = nowUtc.year - 1; y >= firstVisibleStart.year; y--) {
          keys.add('$y');
        }
        return keys;
    }
  }
}
