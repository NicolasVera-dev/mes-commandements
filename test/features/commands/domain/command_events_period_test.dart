import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command_events_period.dart';

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
}
