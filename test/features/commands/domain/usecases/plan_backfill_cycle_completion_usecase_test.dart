import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/usecases/plan_backfill_cycle_completion_usecase.dart';

void main() {
  group('PlanBackfillCycleCompletionUseCase', () {
    const useCase = PlanBackfillCycleCompletionUseCase();

    test('autorise un cycle passé non complété et garde la bonne clé', () {
      final plan = useCase.execute(
        frequency: Frequency.daily,
        cycleKey: '2026-03-10',
        isAlreadyCompleted: false,
        nowUtc: DateTime.utc(2026, 3, 15, 9),
      );

      expect(plan.cycleKey, '2026-03-10');
      expect(plan.actionAtUtc, DateTime.utc(2026, 3, 10, 23, 59, 59));
    });

    test('refuse le cycle courant', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.daily,
          cycleKey: '2026-03-15',
          isAlreadyCompleted: false,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<BackfillCycleRejected>().having(
            (e) => e.reason,
            'reason',
            BackfillCycleRejectionReason.currentCycle,
          ),
        ),
      );
    });

    test('refuse un cycle futur', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.monthly,
          cycleKey: '2026-04',
          isAlreadyCompleted: false,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<BackfillCycleRejected>().having(
            (e) => e.reason,
            'reason',
            BackfillCycleRejectionReason.futureCycle,
          ),
        ),
      );
    });

    test('refuse un cycle déjà complété', () {
      expect(
        () => useCase.execute(
          frequency: Frequency.yearly,
          cycleKey: '2025',
          isAlreadyCompleted: true,
          nowUtc: DateTime.utc(2026, 3, 15, 9),
        ),
        throwsA(
          isA<BackfillCycleRejected>().having(
            (e) => e.reason,
            'reason',
            BackfillCycleRejectionReason.cycleAlreadyCompleted,
          ),
        ),
      );
    });

    test('normalise une clé hebdomadaire legacy -W vers -S', () {
      final plan = useCase.execute(
        frequency: Frequency.weekly,
        cycleKey: '2026-W09',
        isAlreadyCompleted: false,
        nowUtc: DateTime.utc(2026, 3, 15, 9),
      );

      expect(plan.cycleKey, '2026-S09');
      expect(plan.actionAtUtc, DateTime.utc(2026, 3, 1, 23, 59, 59));
    });
  });
}
