import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/usecases/plan_edit_cycle_event_cleanup_usecase.dart';

void main() {
  group('PlanEditCycleEventCleanupUseCase', () {
    const useCase = PlanEditCycleEventCleanupUseCase();

    Command build({
      required int progress,
      required int target,
      required Frequency frequency,
    }) {
      return Command(
        id: 'cmd-1',
        title: 'Lire',
        target: target,
        progress: progress,
        frequency: frequency,
      );
    }

    test('Édition target à la hausse : purge du cycle en cours', () {
      final before = build(
        progress: 10,
        target: 10,
        frequency: Frequency.daily,
      );
      final after = before.copyWith(
        target: 20,
        progress: 9,
      );

      final result = useCase.execute(before: before, after: after);
      expect(result, EditEventCleanupScope.currentCycleOnly);
    });

    test('Édition target à la baisse : purge du cycle en cours', () {
      final before = build(
        progress: 10,
        target: 10,
        frequency: Frequency.daily,
      );
      final after = before.copyWith(
        target: 8,
        progress: 10,
      );

      final result = useCase.execute(before: before, after: after);
      expect(result, EditEventCleanupScope.currentCycleOnly);
    });

    test('Changement de fréquence : purge totale', () {
      final before = build(
        progress: 4,
        target: 4,
        frequency: Frequency.daily,
      );
      final after = before.copyWith(
        frequency: Frequency.weekly,
      );

      final result = useCase.execute(before: before, after: after);
      expect(result, EditEventCleanupScope.allEvents);
    });

    test('Édition sans changement de statut completed mais progression modifiée : purge cycle courant', () {
      final before = build(
        progress: 3,
        target: 10,
        frequency: Frequency.monthly,
      );
      final after = before.copyWith(
        progress: 4,
      );

      final result = useCase.execute(before: before, after: after);
      expect(result, EditEventCleanupScope.currentCycleOnly);
    });

    test('Édition sans changement progress/target/frequency : pas de purge', () {
      final before = build(
        progress: 3,
        target: 10,
        frequency: Frequency.monthly,
      );
      final after = before.copyWith(
        title: 'Lire davantage',
      );

      final result = useCase.execute(before: before, after: after);
      expect(result, EditEventCleanupScope.none);
    });
  });
}
