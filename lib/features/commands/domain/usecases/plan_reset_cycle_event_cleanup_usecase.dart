import '../entities/command_event.dart';

class PlanResetCycleEventCleanupUseCase {
  const PlanResetCycleEventCleanupUseCase();

  List<CommandEvent> eventsToDelete({
    required String currentCycleKey,
    required List<CommandEvent> allEvents,
  }) {
    return allEvents
        .where((event) => event.cycleKey == currentCycleKey)
        .where(
          (event) =>
              event.type == CommandEventType.increment ||
              event.type == CommandEventType.complete,
        )
        .toList(growable: false);
  }
}
