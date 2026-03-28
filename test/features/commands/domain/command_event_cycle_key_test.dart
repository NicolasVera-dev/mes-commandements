import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_event.dart';
import 'package:mes_commandements/features/commands/domain/services/cycle_key_generator.dart';

void main() {
  group('CycleKeyGenerator', () {
    test('daily -> YYYY-MM-DD', () {
      final key = CycleKeyGenerator.forFrequency(
        frequency: Frequency.daily,
        atUtc: DateTime.utc(2026, 3, 26, 14, 10),
      );
      expect(key, '2026-03-26');
    });

    test('weekly -> YYYY-Sww (ISO week, format FR)', () {
      final key = CycleKeyGenerator.forFrequency(
        frequency: Frequency.weekly,
        atUtc: DateTime.utc(2026, 3, 26, 14, 10), // jeudi semaine 13
      );
      expect(key, '2026-S13');
    });

    test('weekly handles year boundary with ISO week year', () {
      final key = CycleKeyGenerator.forFrequency(
        frequency: Frequency.weekly,
        atUtc: DateTime.utc(2021, 1, 1, 10, 0), // ISO week 53 of 2020
      );
      expect(key, '2020-S53');
    });

    test('monthly -> YYYY-MM', () {
      final key = CycleKeyGenerator.forFrequency(
        frequency: Frequency.monthly,
        atUtc: DateTime.utc(2026, 3, 26, 14, 10),
      );
      expect(key, '2026-03');
    });

    test('yearly -> YYYY', () {
      final key = CycleKeyGenerator.forFrequency(
        frequency: Frequency.yearly,
        atUtc: DateTime.utc(2026, 3, 26, 14, 10),
      );
      expect(key, '2026');
    });
  });

  group('CommandEvent', () {
    test('builds deterministic event snapshot from command', () {
      final command = Command(
        id: 'c1',
        title: 'Hydratation',
        target: 8,
        progress: 5,
        frequency: Frequency.daily,
      );
      final atUtc = DateTime.utc(2026, 3, 26, 8, 0);

      final event = CommandEvent.fromCommandSnapshot(
        type: CommandEventType.increment,
        command: command,
        actionAtUtc: atUtc,
      );

      expect(event.type, CommandEventType.increment);
      expect(event.actionAtUtc, atUtc);
      expect(event.progressAfterAction, 5);
      expect(event.targetAtAction, 8);
      expect(event.cycleKey, '2026-03-26');
    });

    test('command helper toEvent uses same deterministic cycleKey', () {
      final command = Command(
        id: 'c2',
        title: 'Sprint',
        target: 10,
        progress: 10,
        frequency: Frequency.weekly,
      );
      final atUtc = DateTime.utc(2026, 3, 26, 10, 30);

      final event = command.toEvent(
        type: CommandEventType.complete,
        actionAtUtc: atUtc,
      );

      expect(event.type, CommandEventType.complete);
      expect(event.cycleKey, '2026-S13');
      expect(event.progressAfterAction, 10);
      expect(event.targetAtAction, 10);
    });
  });
}
