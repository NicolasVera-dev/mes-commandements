import '../services/cycle_key_generator.dart';
import 'command.dart';

class CommandEventsPeriod {
  final DateTime startUtc;
  final DateTime endUtc;

  const CommandEventsPeriod({
    required this.startUtc,
    required this.endUtc,
  });

  factory CommandEventsPeriod.currentMonth(DateTime nowUtc) {
    final now = nowUtc.toUtc();
    final start = DateTime.utc(now.year, now.month, 1);
    final end = now.month == 12
        ? DateTime.utc(now.year + 1, 1, 1)
        : DateTime.utc(now.year, now.month + 1, 1);
    return CommandEventsPeriod(startUtc: start, endUtc: end);
  }

  /// Fenêtre pour charger les événements d’historique lorsque l’UI est ancrée sur
  /// un mois calendaire : inclut toute semaine ISO qui intersecte ce mois (y compris
  /// les jours en dehors du mois), afin que les actions enregistrées en fin de semaine
  /// restent visibles avec la même clé de cycle partout.
  factory CommandEventsPeriod.forIsoWeeksTouchingCalendarMonthUtc(
    DateTime anchorMonthUtc,
  ) {
    final a = anchorMonthUtc.toUtc();
    final y = a.year;
    final m = a.month;
    final monthStart = DateTime.utc(y, m, 1);
    final monthEndExclusive = m == 12
        ? DateTime.utc(y + 1, 1, 1)
        : DateTime.utc(y, m + 1, 1);
    final lastDay = monthEndExclusive.subtract(const Duration(days: 1));
    final firstMonday = CycleKeyGenerator.cycleStartUtc(
      Frequency.weekly,
      monthStart,
    );
    final lastMonday = CycleKeyGenerator.cycleStartUtc(
      Frequency.weekly,
      lastDay,
    );
    return CommandEventsPeriod(
      startUtc: firstMonday,
      endUtc: lastMonday.add(const Duration(days: 7)),
    );
  }
}
