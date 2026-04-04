/// Calcule les prochains créneaux de rappel en date/heure **locales** (sans dépendance Flutter).
///
/// Toutes les comparaisons utilisent [now] tel quel (interprété comme instant local).
class ReminderSlotCalculator {
  const ReminderSlotCalculator();

  /// Prochain rappel quotidien à [hour]:[minute], strictement après [now].
  DateTime nextDailySlot(DateTime now, int hour, int minute) {
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year, now.month, now.day + 1, hour, minute);
    }
    return candidate;
  }

  /// Prochains mercredis et dimanches à [hour]:[minute], après [now] (0, 1 ou 2 dates).
  List<DateTime> nextWeeklyWednesdayAndSunday(
    DateTime now,
    int hour,
    int minute,
  ) {
    final wed = _nextWeekdayOccurrence(
      now,
      DateTime.wednesday,
      hour,
      minute,
    );
    final sun = _nextWeekdayOccurrence(
      now,
      DateTime.sunday,
      hour,
      minute,
    );
    final set = <DateTime>{wed, sun}..removeWhere((d) => !d.isAfter(now));
    final list = set.toList()..sort();
    return list;
  }

  /// Prochain rappel « 7 jours avant la fin du mois », après [now].
  DateTime? nextMonthlySevenDaysBeforeEnd(DateTime now, int hour, int minute) {
    return _nextMonthRelativeSlot(
      now,
      hour,
      minute,
      daysBeforeEnd: 7,
    );
  }

  /// Prochain rappel « 2 jours avant la fin du mois », après [now].
  DateTime? nextMonthlyTwoDaysBeforeEnd(DateTime now, int hour, int minute) {
    return _nextMonthRelativeSlot(
      now,
      hour,
      minute,
      daysBeforeEnd: 2,
    );
  }

  /// Prochains 1er novembre et 1er décembre à [hour]:[minute], après [now].
  List<DateTime> nextYearlyNovemberAndDecemberFirst(
    DateTime now,
    int hour,
    int minute,
  ) {
    final nov = _nextAnnualCalendarDay(11, 1, now, hour, minute);
    final dec = _nextAnnualCalendarDay(12, 1, now, hour, minute);
    return <DateTime>[nov, dec]..sort();
  }

  DateTime _nextWeekdayOccurrence(
    DateTime now,
    int targetWeekday,
    int hour,
    int minute,
  ) {
    final y = now.year;
    final m = now.month;
    final d = now.day;
    final todaySlot = DateTime(y, m, d, hour, minute);
    var deltaDays = targetWeekday - now.weekday;
    if (deltaDays < 0) {
      deltaDays += 7;
    }
    if (deltaDays == 0 && !todaySlot.isAfter(now)) {
      deltaDays = 7;
    }
    // Jour calendaire (pas Duration(days: n)) pour garder l’heure locale aux
    // transitions DST (ex. US : mars).
    return DateTime(y, m, d + deltaDays, hour, minute);
  }

  /// Dernier jour calendaire du mois (date à minuit local).
  DateTime lastCalendarDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  /// Jour du mois à [daysBeforeEnd] jours avant le dernier jour (inclus).
  /// Ex. fin 31 → J-7 = 24, J-2 = 29.
  DateTime slotDayBeforeMonthEnd(
    int year,
    int month,
    int hour,
    int minute, {
    required int daysBeforeEnd,
  }) {
    final last = lastCalendarDayOfMonth(year, month);
    final day = last.day - daysBeforeEnd;
    return DateTime(year, month, day, hour, minute);
  }

  DateTime? _nextMonthRelativeSlot(
    DateTime now,
    int hour,
    int minute, {
    required int daysBeforeEnd,
  }) {
    for (var i = 0; i < 36; i++) {
      final anchor = DateTime(now.year, now.month + i, 1);
      final slot = slotDayBeforeMonthEnd(
        anchor.year,
        anchor.month,
        hour,
        minute,
        daysBeforeEnd: daysBeforeEnd,
      );
      if (slot.isAfter(now)) {
        return slot;
      }
    }
    return null;
  }

  DateTime _nextAnnualCalendarDay(
    int month,
    int day,
    DateTime now,
    int hour,
    int minute,
  ) {
    var candidate = DateTime(now.year, month, day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = DateTime(now.year + 1, month, day, hour, minute);
    }
    return candidate;
  }
}
