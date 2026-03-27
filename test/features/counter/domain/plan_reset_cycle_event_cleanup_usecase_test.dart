import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/features/counter/domain/entities/command_event.dart';
import 'package:mes_commandements/features/counter/domain/usecases/plan_reset_cycle_event_cleanup_usecase.dart';

void main() {
  group('PlanResetCycleEventCleanupUseCase', () {
    const useCase = PlanResetCycleEventCleanupUseCase();

    CommandEvent build({
      required CommandEventType type,
      required String cycleKey,
    }) {
      return CommandEvent(
        type: type,
        actionAtUtc: DateTime.utc(2026, 3, 20),
        progressAfterAction: 1,
        targetAtAction: 5,
        cycleKey: cycleKey,
      );
    }

    test('supprime uniquement increment et complete du cycle courant', () {
      final events = <CommandEvent>[
        build(type: CommandEventType.increment, cycleKey: '2026-S13'),
        build(type: CommandEventType.complete, cycleKey: '2026-S13'),
        build(type: CommandEventType.resetManual, cycleKey: '2026-S13'),
        build(type: CommandEventType.increment, cycleKey: '2026-S12'),
        build(type: CommandEventType.complete, cycleKey: '2026-S12'),
      ];

      final toDelete = useCase.eventsToDelete(
        currentCycleKey: '2026-S13',
        allEvents: events,
      );

      expect(toDelete.length, 2);
      expect(toDelete.every((e) => e.cycleKey == '2026-S13'), isTrue);
      expect(
        toDelete.map((e) => e.type).toSet(),
        {CommandEventType.increment, CommandEventType.complete},
      );
    });
  });
}
