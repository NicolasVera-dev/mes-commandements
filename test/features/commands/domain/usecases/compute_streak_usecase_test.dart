import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/services/cycle_key_generator.dart';
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
  const milestoneCases = {
    Frequency.daily: (
      [2, 3, 5, 7, 14, 30, 60, 100],
      [1, 2, 3, 5, 7, 10, 14, 21],
    ),
    Frequency.weekly: ([2, 3, 4, 6, 8, 12, 26, 52], [1, 2, 3, 4, 5, 6, 8, 12]),
    Frequency.monthly: ([2, 3, 4, 6, 9, 12, 18, 24], [1, 2, 3, 4, 5, 6, 9, 12]),
    Frequency.yearly: ([2, 3, 4, 5, 6, 8, 10, 15], [1, 2, 3, 4, 5, 6, 7, 8]),
  };
  const positiveBadges = [
    StreakBadge.goodStart,
    StreakBadge.inRhythm,
    StreakBadge.solidStreak,
    StreakBadge.consistent,
    StreakBadge.momentum,
    StreakBadge.milestone,
    StreakBadge.established,
    StreakBadge.legendary,
  ];
  const negativeBadges = [
    StreakBadge.missedOccasion,
    StreakBadge.setback,
    StreakBadge.findRhythm,
    StreakBadge.slowingDown,
    StreakBadge.adjustGoal,
    StreakBadge.smallStep,
    StreakBadge.freshStart,
    StreakBadge.rethinkDirection,
  ];

  for (final entry in milestoneCases.entries) {
    final frequency = entry.key;
    final (positive, negative) = entry.value;
    test('seuils positifs et négatifs pour ${frequency.name}', () {
      for (final (thresholds, badges, success) in [
        (positive, positiveBadges, true),
        (negative, negativeBadges, false),
      ]) {
        for (var i = 0; i < thresholds.length; i++) {
          final threshold = thresholds[i];
          final atThreshold = _streak(frequency, threshold, success: success);
          expect(atThreshold.badge, badges[i], reason: 'Seuil $threshold');
          expect(atThreshold.count, threshold);
          final before = _streak(frequency, threshold - 1, success: success);
          expect(before.badge, i == 0 ? StreakBadge.none : badges[i - 1]);
        }
        final beyond = _streak(
          frequency,
          thresholds.last + 5,
          success: success,
        );
        expect(beyond.badge, badges.last);
        expect(beyond.count, thresholds.last + 5);
      }
    });
  }

  test('une reprise devient Bon départ à la prochaine occasion réussie', () {
    final command = Command(
      id: 'c1',
      title: 'Lecture',
      target: 1,
      progress: 1,
      frequency: Frequency.daily,
      createdAt: DateTime.utc(2026, 4, 6),
      lastResetAt: DateTime.utc(2026, 4, 9),
      activeWeekdays: const [
        DateTime.monday,
        DateTime.tuesday,
        DateTime.thursday,
      ],
    );
    final result = const ComputeStreakUseCase().execute(
      command: command,
      grouped: {
        '2026-04-07': [_complete(cycleKey: '2026-04-07')],
      },
      createdAtUtc: command.createdAt!,
      nowUtc: DateTime.utc(2026, 4, 9, 12),
    );
    expect(result.badge, StreakBadge.goodStart);
    expect(result.count, 2);
  });

  test('une progression du cycle précédent ne déclenche pas une reprise', () {
    final command = Command(
      id: 'c1',
      title: 'Lecture',
      target: 1,
      progress: 1,
      frequency: Frequency.daily,
      createdAt: DateTime.utc(2026, 4, 1),
      lastResetAt: DateTime.utc(2026, 4, 1),
    );
    final result = const ComputeStreakUseCase().execute(
      command: command,
      grouped: {},
      createdAtUtc: command.createdAt!,
      nowUtc: DateTime.utc(2026, 4, 2),
    );
    expect(result.badge, StreakBadge.missedOccasion);
    expect(result.count, 1);
  });

  group('ComputeStreakUseCase', () {
    const created = '2026-01-01';
    final createdAt = DateTime.parse('${created}T00:00:00Z');
    final now = DateTime.utc(2026, 4, 3, 12);

    test('série positive : 3 cycles passés réussis → En rythme', () {
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

      expect(r.badge, StreakBadge.inRhythm);
      expect(r.count, 3);
    });

    test(
      'série négative : 3 cycles passés sans succès → Rythme à retrouver',
      () {
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

        expect(r.badge, StreakBadge.findRhythm);
        expect(r.count, 3);
      },
    );

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

        expect(r.badge, StreakBadge.findRhythm);
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
      expect(r.badge, StreakBadge.setback);
      expect(r.count, 2);
    });

    test('série positive : le compteur inclut le jour courant lorsqu’il est complété', () {
      final command = Command(
        id: 'c1',
        title: 't',
        target: 1,
        progress: 1,
        lastResetAt: now,
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

      expect(r.badge, StreakBadge.inRhythm);
      expect(r.count, 4);
    });

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

      expect(r.badge, StreakBadge.recovered);
      expect(r.count, 2);
    });
  });
}

StreakResult _streak(Frequency frequency, int count, {required bool success}) {
  final created = DateTime.utc(2000, 1, 3);
  DateTime cycleAt(int index) => switch (frequency) {
    Frequency.daily => DateTime.utc(2000, 1, 3 + index),
    Frequency.weekly => DateTime.utc(2000, 1, 3 + 7 * index),
    Frequency.monthly => DateTime.utc(2000, 1 + index, 3),
    Frequency.yearly => DateTime.utc(2000 + index, 1, 3),
  };
  final command = Command(
    id: 'c1',
    title: 'Lecture',
    target: 1,
    progress: 0,
    frequency: frequency,
    createdAt: created,
  );
  final grouped = <String, List<CommandEvent>>{};
  if (success) {
    for (var i = 0; i < count; i++) {
      final cycle = cycleAt(i);
      final key = CycleKeyGenerator.forFrequency(
        frequency: frequency,
        atUtc: cycle,
      );
      grouped[key] = [_complete(cycleKey: key, actionAtUtc: cycle)];
    }
  }
  return const ComputeStreakUseCase().execute(
    command: command,
    grouped: grouped,
    createdAtUtc: created,
    nowUtc: cycleAt(count),
  );
}
