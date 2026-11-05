import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_events_period.dart';
import 'package:rituel/features/commands/domain/services/cycle_key_generator.dart';

void main() {
  group('CommandEventsPeriod.currentMonth', () {
    test('calcule le début et la fin UTC du mois courant', () {
      final period = CommandEventsPeriod.currentMonth(
        DateTime.utc(2026, 3, 26, 14, 30),
      );

      expect(period.startUtc, DateTime.utc(2026, 3, 1));
      expect(period.endUtc, DateTime.utc(2026, 4, 1));
    });

    test('gère le passage décembre -> janvier', () {
      final period = CommandEventsPeriod.currentMonth(
        DateTime.utc(2026, 12, 15, 9, 0),
      );

      expect(period.startUtc, DateTime.utc(2026, 12, 1));
      expect(period.endUtc, DateTime.utc(2027, 1, 1));
    });
  });

  group('CommandEventsPeriod.forIsoWeeksTouchingCalendarMonthUtc', () {
    test(
      'couvre du lundi de la semaine du 1er au lundi suivant la dernière semaine du mois',
      () {
        final anchor = DateTime.utc(2026, 5, 1);
        final period =
            CommandEventsPeriod.forIsoWeeksTouchingCalendarMonthUtc(anchor);
        final monthStart = DateTime.utc(2026, 5, 1);
        final monthEndExclusive = DateTime.utc(2026, 6, 1);
        final lastDay = monthEndExclusive.subtract(const Duration(days: 1));
        expect(
          period.startUtc,
          CycleKeyGenerator.cycleStartUtc(Frequency.weekly, monthStart),
        );
        expect(
          period.endUtc,
          CycleKeyGenerator.cycleStartUtc(Frequency.weekly, lastDay).add(
            const Duration(days: 7),
          ),
        );
      },
    );

    test('inclut des jours du mois précédent si le 1er nest pas lundi', () {
      final period =
          CommandEventsPeriod.forIsoWeeksTouchingCalendarMonthUtc(
        DateTime.utc(2026, 5, 1),
      );
      expect(period.startUtc.isBefore(DateTime.utc(2026, 5, 1)), isTrue);
    });
  });
}
