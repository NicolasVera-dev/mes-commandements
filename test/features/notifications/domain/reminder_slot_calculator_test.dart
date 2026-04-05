import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/notifications/domain/reminder_slot_calculator.dart';

void main() {
  const calc = ReminderSlotCalculator();

  group('ReminderSlotCalculator', () {
    test('quotidien : même jour si l’heure de rappel est encore à venir', () {
      final now = DateTime(2025, 3, 10, 10, 0);
      final slot = calc.nextDailySlot(now, 18, 0);
      expect(slot, DateTime(2025, 3, 10, 18, 0));
    });

    test('quotidien : lendemain si l’heure est déjà passée', () {
      final now = DateTime(2025, 3, 10, 19, 30);
      final slot = calc.nextDailySlot(now, 18, 0);
      expect(slot, DateTime(2025, 3, 11, 18, 0));
    });

    test('hebdo : prochain mercredi et dimanche après un mardi', () {
      final now = DateTime(2025, 3, 4, 10, 0);
      final slots = calc.nextWeeklyWednesdayAndSunday(now, 18, 0);
      expect(slots.length, 2);
      expect(slots[0], DateTime(2025, 3, 5, 18, 0));
      expect(slots[1], DateTime(2025, 3, 9, 18, 0));
    });

    test('hebdo : mercredi suivant si on est mercredi après l’heure', () {
      final now = DateTime(2025, 3, 5, 20, 0);
      final slots = calc.nextWeeklyWednesdayAndSunday(now, 18, 0);
      final wed = slots.firstWhere(
        (d) => d.weekday == DateTime.wednesday,
      );
      expect(wed, DateTime(2025, 3, 12, 18, 0));
    });

    test('mensuel : J-7 et J-2 fin de mois (mars 31)', () {
      final last = calc.lastCalendarDayOfMonth(2025, 3);
      expect(last.day, 31);
      expect(
        calc.slotDayBeforeMonthEnd(2025, 3, 18, 0, daysBeforeEnd: 7),
        DateTime(2025, 3, 24, 18, 0),
      );
      expect(
        calc.slotDayBeforeMonthEnd(2025, 3, 18, 0, daysBeforeEnd: 2),
        DateTime(2025, 3, 29, 18, 0),
      );
    });

    test('mensuel : passage décembre → janvier quand fin décembre déjà passée', () {
      final now = DateTime(2025, 12, 30, 12, 0);
      final j7 = calc.nextMonthlySevenDaysBeforeEnd(now, 18, 0);
      final j2 = calc.nextMonthlyTwoDaysBeforeEnd(now, 18, 0);
      expect(j7, DateTime(2026, 1, 24, 18, 0));
      expect(j2, DateTime(2026, 1, 29, 18, 0));
    });

    test('annuel : 1er nov et 1er déc après mi-novembre', () {
      final now = DateTime(2025, 11, 15, 12, 0);
      final slots = calc.nextYearlyNovemberAndDecemberFirst(now, 18, 0);
      expect(slots.length, 2);
      expect(slots[0], DateTime(2025, 12, 1, 18, 0));
      expect(slots[1], DateTime(2026, 11, 1, 18, 0));
    });

    test('annuel : après décembre, nov et déc de l’année suivante', () {
      final now = DateTime(2025, 12, 20, 12, 0);
      final slots = calc.nextYearlyNovemberAndDecemberFirst(now, 9, 30);
      expect(slots[0], DateTime(2026, 11, 1, 9, 30));
      expect(slots[1], DateTime(2026, 12, 1, 9, 30));
    });
  });
}
