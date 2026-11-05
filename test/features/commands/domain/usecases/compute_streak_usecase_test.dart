import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/usecases/compute_streak_usecase.dart';

CommandEvent _complete({required String cycleKey, DateTime? actionAtUtc}) {
  return CommandEvent(
    type: CommandEventType.complete,
    actionAtUtc: actionAtUtc ?? DateTime.utc(2026, 4, 2, 12),
    progressAfterAction: 3,
    targetAtAction: 3,
    cycleKey: cycleKey,
  );
}

void main() {
  group('ComputeStreakUseCase', () {
    const created = '2026-01-01';
    final createdAt = DateTime.parse('${created}T00:00:00Z');
    final now = DateTime.utc(2026, 4, 3, 12);

    test('série positive : au moins 3 cycles passés réussis → success1', () {
      final command = Command(
        id: 'c1',
        title: 't',
        target: 3,
        progress: 0,
        frequency: Frequency.daily,
        createdAt: createdAt,
      );
      final grouped = <String, List<CommandEvent>>{
        '2026-04-02': [_complete(cycleKey: '2026-04-02')],
        '2026-04-01': [_complete(cycleKey: '2026-04-01')],
        '2026-03-31': [_complete(cycleKey: '2026-03-31')],
      };

      final r = const ComputeStreakUseCase().execute(
        command: command,
        grouped: grouped,
        createdAtUtc: createdAt,
        nowUtc: now,
      );

      expect(r.badge, StreakBadge.success1);
      expect(r.count, 3);
    });

    test('série négative : ≥3 cycles passés sans succès → failDaily', () {
      final createdForNegative = DateTime.utc(2026, 3, 31);
      final command = Command(
        id: 'c1',
        title: 't',
        target: 3,
        progress: 0,
        frequency: Frequency.daily,
        createdAt: createdForNegative,
      );
      final grouped = <String, List<CommandEvent>>{
        '2026-04-02': const <CommandEvent>[],
        '2026-04-01': const <CommandEvent>[],
        '2026-03-31': const <CommandEvent>[],
      };

      final r = const ComputeStreakUseCase().execute(
        command: command,
        grouped: grouped,
        createdAtUtc: createdForNegative,
        nowUtc: now,
      );

      expect(r.badge, StreakBadge.failDaily);
      expect(r.count, 3);
    });

    test(
      'série négative : cycles passés sans événement sont comptés en échec',
      () {
        final command = Command(
          id: 'c1',
          title: 't',
          target: 3,
          progress: 0,
          frequency: Frequency.daily,
          createdAt: DateTime.utc(2026, 4, 1),
        );

        final r = const ComputeStreakUseCase().execute(
          command: command,
          grouped: const <String, List<CommandEvent>>{},
          createdAtUtc: DateTime.utc(2026, 4, 1),
          nowUtc: DateTime.utc(2026, 4, 5, 12),
        );

        expect(r.badge, StreakBadge.failDaily);
        expect(r.count, 4);
      },
    );

    test('série ignore les jours inactifs sur un quotidien', () {
      final command = Command(
        id: 'c1',
        title: 't',
        target: 3,
        progress: 0,
        frequency: Frequency.daily,
        createdAt: DateTime.utc(2026, 4, 3), // vendredi
        activeWeekdays: const <int>[
          DateTime.monday,
          DateTime.tuesday,
          DateTime.wednesday,
          DateTime.thursday,
          DateTime.friday,
        ],
      );

      final r = const ComputeStreakUseCase().execute(
        command: command,
        grouped: const <String, List<CommandEvent>>{},
        createdAtUtc: DateTime.utc(2026, 4, 3),
        nowUtc: DateTime.utc(2026, 4, 7, 12), // mardi
      );

      // Cycles actifs passés : vendredi + lundi = 2 (samedi/dimanche ignorés)
      expect(r.badge, StreakBadge.none);
      expect(r.count, 0);
    });

    test(
      'série positive : le compteur inclut le jour courant lorsqu’il est complété',
      () {
        final command = Command(
          id: 'c1',
          title: 't',
          target: 1,
          progress: 1,
          frequency: Frequency.daily,
          createdAt: createdAt,
        );
        final grouped = <String, List<CommandEvent>>{
          '2026-04-02': [_complete(cycleKey: '2026-04-02')],
          '2026-04-01': [_complete(cycleKey: '2026-04-01')],
          '2026-03-31': [_complete(cycleKey: '2026-03-31')],
        };

        final r = const ComputeStreakUseCase().execute(
          command: command,
          grouped: grouped,
          createdAtUtc: createdAt,
          nowUtc: now,
        );

        expect(r.badge, StreakBadge.success1);
        expect(r.count, 4);
      },
    );

    test('reprise : succès sur le cycle courant après échecs passés', () {
      final createdForRecovery = DateTime.utc(2026, 4, 1);
      final command = Command(
        id: 'c1',
        title: 't',
        target: 3,
        progress: 3,
        frequency: Frequency.daily,
        createdAt: createdForRecovery,
      );
      final grouped = <String, List<CommandEvent>>{
        '2026-04-03': [_complete(cycleKey: '2026-04-03')],
        '2026-04-02': const <CommandEvent>[],
        '2026-04-01': const <CommandEvent>[],
      };

      final r = const ComputeStreakUseCase().execute(
        command: command,
        grouped: grouped,
        createdAtUtc: createdForRecovery,
        nowUtc: now,
      );

      expect(r.badge, StreakBadge.recoveredToday);
      expect(r.count, 2);
    });
  });
}
