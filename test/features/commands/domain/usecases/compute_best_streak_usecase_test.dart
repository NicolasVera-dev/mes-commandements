import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/entities/command_pause.dart';
import 'package:rituel/features/commands/domain/usecases/compute_best_streak_usecase.dart';

void main() {
  final start = DateTime.utc(2026, 11, 1);
  test(
    'best streak survives missed cycles and includes a completed current cycle',
    () {
      final command = Command(
        id: 'c',
        title: 'Marcher',
        target: 1,
        progress: 1,
        frequency: Frequency.daily,
        createdAt: start,
        lastResetAt: DateTime.utc(2026, 11, 8),
      );
      final grouped = <String, List<CommandEvent>>{};
      for (final n in [1, 2, 3, 5, 7]) {
        final date = DateTime.utc(2026, 11, n);
        grouped[command.cycleKeyAt(date)] = [
          command.toEvent(type: CommandEventType.complete, actionAtUtc: date),
        ];
      }
      expect(
        const ComputeBestStreakUseCase().execute(
          command: command,
          grouped: grouped,
          createdAtUtc: start,
          nowUtc: DateTime.utc(2026, 11, 8),
        ),
        3,
      );
      expect(
        const ComputeBestStreakUseCase().execute(
          command: command,
          grouped: {},
          createdAtUtc: start,
          nowUtc: DateTime.utc(2026, 11, 8),
        ),
        1,
      );
    },
  );
  test('paused missed days are neutral and successes in a paused cycle still count', () {
    final command = Command(
      id: 'c',
      title: 'Lire',
      target: 1,
      progress: 0,
      frequency: Frequency.daily,
      createdAt: start,
      pauses: [
        CommandPause(
          startUtc: start.add(const Duration(days: 1)),
          endUtc: start.add(const Duration(days: 2)),
        ),
      ],
    );
    final grouped = <String, List<CommandEvent>>{};
    for (final n in [0, 2]) {
      final date = start.add(Duration(days: n));
      grouped[command.cycleKeyAt(date)] = [
        command.toEvent(type: CommandEventType.complete, actionAtUtc: date),
      ];
    }
    expect(
      const ComputeBestStreakUseCase().execute(
        command: command,
        grouped: grouped,
        createdAtUtc: start,
        nowUtc: start.add(const Duration(days: 4)),
      ),
      2,
    );
  });
  test('weekly and monthly records count cycles rather than days', () {
    for (final frequency in [Frequency.weekly, Frequency.monthly]) {
      final date = DateTime.utc(2026, 1, 1);
      final command = Command(
        id: 'c',
        title: 'Lire',
        target: 1,
        progress: 0,
        frequency: frequency,
        createdAt: date,
      );
      final dates = frequency == Frequency.weekly
          ? [DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 5)]
          : [date, DateTime.utc(2026, 2, 1)];
      final grouped = {
        for (final d in dates)
          command.cycleKeyAt(d): [
            command.toEvent(type: CommandEventType.complete, actionAtUtc: d),
          ],
      };
      expect(
        const ComputeBestStreakUseCase().execute(
          command: command,
          grouped: grouped,
          createdAtUtc: date,
          nowUtc: DateTime.utc(2026, 3, 1),
        ),
        2,
      );
    }
  });
}
