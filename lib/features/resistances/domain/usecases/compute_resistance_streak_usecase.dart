import '../entities/resistance.dart';

/// Calcule le streak courant en **jours calendaires UTC** depuis la création
/// ou depuis le jour de la dernière rechute (même logique que l’après-rechute).
class ComputeResistanceStreakUseCase {
  const ComputeResistanceStreakUseCase();

  /// Jours écoulés sans rechute : **0** le jour de création ou le jour d’une rechute,
  /// puis +1 par jour calendaire UTC suivant.
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
      return diff;
    }

    final lr = resistance.lastRelapseAtUtc!.toUtc();
    final relapseDay = DateTime.utc(lr.year, lr.month, lr.day);

    if (!today.isAfter(relapseDay)) {
      return 0;
    }

    return today.difference(relapseDay).inDays;
  }
}
