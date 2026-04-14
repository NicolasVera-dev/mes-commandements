import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/usecases/plan_remove_cycle_completion_usecase.dart';

void main() {
  group('PlanRemoveCycleCompletionUseCase', () {
    const useCase = PlanRemoveCycleCompletionUseCase();

    test('autorise la suppression de complétion sur un cycle passé', () {
      final plan = useCase.execute(
        frequency: Frequency.daily,
        cycleKey: '2026-03-10',
        isAlreadyCompleted: true,
        nowUtc: DateTime.utc(2026, 3, 15, 9),
      );

      expect(plan.cycleKey, '2026-03-10');
    });

    test('refuse le cycle courant', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.daily,
          cycleKey: '2026-03-15',
          isAlreadyCompleted: true,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<RemoveCycleCompletionRejected>().having(
            (e) => e.reason,
            'reason',
            RemoveCycleCompletionRejectionReason.currentCycle,
          ),
        ),
      );
    });

    test('refuse un cycle futur', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.monthly,
          cycleKey: '2026-04',
          isAlreadyCompleted: true,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<RemoveCycleCompletionRejected>().having(
            (e) => e.reason,
            'reason',
            RemoveCycleCompletionRejectionReason.futureCycle,
          ),
        ),
      );
    });

    test('refuse un cycle non complété', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.yearly,
          cycleKey: '2025',
          isAlreadyCompleted: false,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<RemoveCycleCompletionRejected>().having(
            (e) => e.reason,
            'reason',
            RemoveCycleCompletionRejectionReason.cycleNotCompleted,
          ),
        ),
      );
    });

    test('normalise une clé hebdomadaire legacy -W vers -S', () {
      final plan = useCase.execute(
        frequency: Frequency.weekly,
        cycleKey: '2026-W09',
        isAlreadyCompleted: true,
        nowUtc: DateTime.utc(2026, 3, 15, 9),
      );

      expect(plan.cycleKey, '2026-S09');
    });
  });
}
