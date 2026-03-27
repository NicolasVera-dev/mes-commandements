import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/counter/domain/entities/auto_reset_report.dart';
import 'package:mes_commandements/features/counter/domain/entities/command.dart';
import 'package:mes_commandements/features/counter/domain/entities/command_position_update.dart';

void main() {
  group('AutoResetReport', () {
    test('empty retourne hasResets false', () {
      const report = AutoResetReport.empty();
      expect(report.total, 0);
      expect(report.byFrequency, isEmpty);
      expect(report.hasResets, isFalse);
    });

    test('hasResets true quand total > 0', () {
      const report = AutoResetReport(
        total: 1,
        byFrequency: {Frequency.daily: 1},
      );
      expect(report.hasResets, isTrue);
    });
  });

  group('CommandPositionUpdate', () {
    test('conserve commandId et position', () {
      const update = CommandPositionUpdate(commandId: 'c1', position: 3);
      expect(update.commandId, 'c1');
      expect(update.position, 3);
    });
  });
}
