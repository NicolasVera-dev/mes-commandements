import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/counter/domain/entities/command.dart';
import 'package:mes_commandements/features/counter/domain/entities/command_event.dart';
import 'package:mes_commandements/features/counter/domain/usecases/evaluate_cycle_status_usecase.dart';

void main() {
  group('EvaluateCycleStatusUseCase', () {
    const useCase = EvaluateCycleStatusUseCase();

    CommandEvent completeEvent(String cycleKey) => CommandEvent(
          type: CommandEventType.complete,
          actionAtUtc: DateTime.utc(2026, 3, 20),
          progressAfterAction: 5,
          targetAtAction: 5,
          cycleKey: cycleKey,
        );

    test('retourne hidden si cycle avant createdAt', () {
      final status = useCase.execute(
        frequency: Frequency.daily,
        cycleStartUtc: DateTime.utc(2026, 3, 10),
        createdAtUtc: DateTime.utc(2026, 3, 12),
        nowUtc: DateTime.utc(2026, 3, 20),
        cycleEvents: const <CommandEvent>[],
      );
      expect(status, CycleStatus.hidden);
    });

    test('retourne success si event complete présent', () {
      final status = useCase.execute(
        frequency: Frequency.weekly,
        cycleStartUtc: DateTime.utc(2026, 3, 23),
        createdAtUtc: DateTime.utc(2026, 3, 1),
        nowUtc: DateTime.utc(2026, 3, 25),
        cycleEvents: <CommandEvent>[completeEvent('2026-S13')],
      );
      expect(status, CycleStatus.success);
    });

    test('retourne failed si cycle passé sans complete', () {
      final status = useCase.execute(
        frequency: Frequency.monthly,
        cycleStartUtc: DateTime.utc(2026, 2, 1),
        createdAtUtc: DateTime.utc(2026, 1, 1),
        nowUtc: DateTime.utc(2026, 3, 10),
        cycleEvents: const <CommandEvent>[],
      );
      expect(status, CycleStatus.failed);
    });

    test('retourne inProgress si cycle courant sans complete', () {
      final status = useCase.execute(
        frequency: Frequency.yearly,
        cycleStartUtc: DateTime.utc(2026, 1, 1),
        createdAtUtc: DateTime.utc(2025, 1, 1),
        nowUtc: DateTime.utc(2026, 8, 1),
        cycleEvents: const <CommandEvent>[],
      );
      expect(status, CycleStatus.inProgress);
    });
  });
}
