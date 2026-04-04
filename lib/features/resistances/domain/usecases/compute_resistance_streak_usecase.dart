import '../entities/resistance.dart';

/// Calcule le streak courant en **jours calendaires UTC** depuis la création ou depuis le lendemain du jour de la dernière rechute.
class ComputeResistanceStreakUseCase {
  const ComputeResistanceStreakUseCase();

  /// Jours de suite sans rechute (0 le jour même d’une rechute).
  int execute({
    required Resistance resistance,
    required DateTime nowUtc,
  }) {
    final now = nowUtc.toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    final created = resistance.createdAtUtc.toUtc();
    final createdDay = DateTime.utc(created.year, created.month, created.day);

    if (resistance.lastRelapseAtUtc == null) {
      final diff = today.difference(createdDay).inDays;
      return diff + 1;
    }

    final lr = resistance.lastRelapseAtUtc!.toUtc();
    final relapseDay = DateTime.utc(lr.year, lr.month, lr.day);

    if (!today.isAfter(relapseDay)) {
      return 0;
    }

    return today.difference(relapseDay).inDays;
  }
}
