import '../entities/command.dart';

enum EditEventCleanupScope {
  none,
  currentCycleOnly,
  allEvents,
}

class PlanEditCycleEventCleanupUseCase {
  const PlanEditCycleEventCleanupUseCase();

  EditEventCleanupScope execute({
    required Command before,
    required Command after,
  }) {
    if (before.frequency != after.frequency) {
      return EditEventCleanupScope.allEvents;
    }

    final progressOrTargetChanged =
        before.progress != after.progress || before.target != after.target;
    if (progressOrTargetChanged) {
      return EditEventCleanupScope.currentCycleOnly;
    }

    final wasCompleted = before.isCompleted();
    final isCompletedNow = after.isCompleted();
    if (wasCompleted && !isCompletedNow) {
      return EditEventCleanupScope.currentCycleOnly;
    }

    return EditEventCleanupScope.none;
  }
}
