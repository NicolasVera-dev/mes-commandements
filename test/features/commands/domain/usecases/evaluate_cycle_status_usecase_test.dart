import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_event.dart';
import 'package:mes_commandements/features/commands/domain/usecases/evaluate_cycle_status_usecase.dart';

void main() {
  group('EvaluateCycleStatusUseCase', () {
    const useCase = EvaluateCycleStatusUseCase();

    CommandEvent ev({
      required CommandEventType type,
      required String cycleKey,
    }) {
      return CommandEvent(
        type: type,
        actionAtUtc: DateTime.utc(2026, 3, 15),
        progressAfterAction: 1,
        targetAtAction: 5,
        cycleKey: cycleKey,
      );
    }

    group('entrée vide (aucun événement)', () {
      test('daily cycle courant sans événements → inProgress', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 20),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 20, 10),
            cycleEvents: const [],
          ),
          CycleStatus.inProgress,
        );
      });

      test('daily cycle passé sans événements → failed', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 10),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 20),
            cycleEvents: const [],
          ),
          CycleStatus.failed,
        );
      });
    });

    group('un seul élément dans cycleEvents', () {
      test('un complete → success (daily)', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 20),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 20),
            cycleEvents: [
              ev(type: CommandEventType.complete, cycleKey: 'x'),
            ],
          ),
          CycleStatus.success,
        );
      });

      test('un increment seulement → cycle passé failed (monthly)', () {
        expect(
          useCase.execute(
            frequency: Frequency.monthly,
            cycleStartUtc: DateTime.utc(2026, 2, 1),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 4, 1),
            cycleEvents: [
              ev(type: CommandEventType.increment, cycleKey: '2026-02'),
            ],
          ),
          CycleStatus.failed,
        );
      });
    });

    group('Frequency.daily', () {
      test('hidden si cycle avant createdAt', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 5),
            createdAtUtc: DateTime.utc(2026, 3, 10),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: const [],
          ),
          CycleStatus.hidden,
        );
      });

      test('success avec complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 15),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: [ev(type: CommandEventType.complete, cycleKey: 'k')],
          ),
          CycleStatus.success,
        );
      });

      test('failed cycle passé sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 14),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: const [],
          ),
          CycleStatus.failed,
        );
      });

      test('inProgress cycle futur (après aujourd’hui UTC)', () {
        expect(
          useCase.execute(
            frequency: Frequency.daily,
            cycleStartUtc: DateTime.utc(2026, 3, 25),
            createdAtUtc: DateTime.utc(2026, 3, 1),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: const [],
          ),
          CycleStatus.inProgress,
        );
      });
    });

    group('Frequency.weekly', () {
      test('hidden si semaine avant première semaine visible (createdAt)', () {
        expect(
          useCase.execute(
            frequency: Frequency.weekly,
            cycleStartUtc: DateTime.utc(2026, 3, 2),
            createdAtUtc: DateTime.utc(2026, 3, 10),
            nowUtc: DateTime.utc(2026, 3, 20),
            cycleEvents: const [],
          ),
          CycleStatus.hidden,
        );
      });

      test('success avec complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.weekly,
            cycleStartUtc: DateTime.utc(2026, 3, 17),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 3, 18),
            cycleEvents: [ev(type: CommandEventType.complete, cycleKey: 'w')],
          ),
          CycleStatus.success,
        );
      });

      test('failed semaine passée sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.weekly,
            cycleStartUtc: DateTime.utc(2026, 3, 3),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 3, 20),
            cycleEvents: const [],
          ),
          CycleStatus.failed,
        );
      });

      test('inProgress semaine courante sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.weekly,
            cycleStartUtc: DateTime.utc(2026, 3, 17),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 3, 18),
            cycleEvents: const [],
          ),
          CycleStatus.inProgress,
        );
      });
    });

    group('Frequency.monthly', () {
      test('hidden si mois avant premier mois visible', () {
        expect(
          useCase.execute(
            frequency: Frequency.monthly,
            cycleStartUtc: DateTime.utc(2026, 2, 1),
            createdAtUtc: DateTime.utc(2026, 4, 15),
            nowUtc: DateTime.utc(2026, 6, 1),
            cycleEvents: const [],
          ),
          CycleStatus.hidden,
        );
      });

      test('success avec complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.monthly,
            cycleStartUtc: DateTime.utc(2026, 3, 1),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: [ev(type: CommandEventType.complete, cycleKey: 'm')],
          ),
          CycleStatus.success,
        );
      });

      test('failed mois passé sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.monthly,
            cycleStartUtc: DateTime.utc(2026, 2, 1),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 4, 1),
            cycleEvents: const [],
          ),
          CycleStatus.failed,
        );
      });

      test('inProgress mois courant sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.monthly,
            cycleStartUtc: DateTime.utc(2026, 3, 1),
            createdAtUtc: DateTime.utc(2026, 1, 1),
            nowUtc: DateTime.utc(2026, 3, 15),
            cycleEvents: const [],
          ),
          CycleStatus.inProgress,
        );
      });
    });

    group('Frequency.yearly', () {
      test('hidden si année avant première année visible', () {
        expect(
          useCase.execute(
            frequency: Frequency.yearly,
            cycleStartUtc: DateTime.utc(2024, 1, 1),
            createdAtUtc: DateTime.utc(2026, 6, 1),
            nowUtc: DateTime.utc(2026, 12, 1),
            cycleEvents: const [],
          ),
          CycleStatus.hidden,
        );
      });

      test('success avec complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.yearly,
            cycleStartUtc: DateTime.utc(2026, 1, 1),
            createdAtUtc: DateTime.utc(2020, 1, 1),
            nowUtc: DateTime.utc(2026, 6, 1),
            cycleEvents: [ev(type: CommandEventType.complete, cycleKey: '2026')],
          ),
          CycleStatus.success,
        );
      });

      test('failed année passée sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.yearly,
            cycleStartUtc: DateTime.utc(2025, 1, 1),
            createdAtUtc: DateTime.utc(2020, 1, 1),
            nowUtc: DateTime.utc(2026, 6, 1),
            cycleEvents: const [],
          ),
          CycleStatus.failed,
        );
      });

      test('inProgress année courante sans complete', () {
        expect(
          useCase.execute(
            frequency: Frequency.yearly,
            cycleStartUtc: DateTime.utc(2026, 1, 1),
            createdAtUtc: DateTime.utc(2020, 1, 1),
            nowUtc: DateTime.utc(2026, 6, 1),
            cycleEvents: const [],
          ),
          CycleStatus.inProgress,
        );
      });
    });
  });
}
