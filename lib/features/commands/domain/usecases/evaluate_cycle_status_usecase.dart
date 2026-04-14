import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

enum CycleStatus { success, failed, inProgress, inactive, hidden }

class EvaluateCycleStatusUseCase {
  const EvaluateCycleStatusUseCase();

  CycleStatus execute({
    required Frequency frequency,
    required DateTime cycleStartUtc,
    required DateTime createdAtUtc,
    required DateTime nowUtc,
    required List<CommandEvent> cycleEvents,
    List<int> activeWeekdays = const <int>[],
  }) {
    final cycleStart = CycleKeyGenerator.cycleStartUtc(
      frequency,
      cycleStartUtc.toUtc(),
    );
    final firstVisible = CycleKeyGenerator.cycleStartUtc(
      frequency,
      createdAtUtc.toUtc(),
    );
    if (cycleStart.isBefore(firstVisible)) {
      return CycleStatus.hidden;
    }

    if (frequency == Frequency.daily &&
        !_isActiveDailyCycle(cycleStart, activeWeekdays)) {
      return CycleStatus.inactive;
    }

    final hasComplete = cycleEvents.any(
      (e) => e.type == CommandEventType.complete,
    );
    if (hasComplete) return CycleStatus.success;

    final currentStart = CycleKeyGenerator.cycleStartUtc(
      frequency,
      nowUtc.toUtc(),
    );
    if (cycleStart.isAtSameMomentAs(currentStart)) {
      return CycleStatus.inProgress;
    }
    if (cycleStart.isBefore(currentStart)) {
      return CycleStatus.failed;
    }
    return CycleStatus.inProgress;
  }

  bool _isActiveDailyCycle(DateTime cycleStartUtc, List<int> activeWeekdays) {
    if (activeWeekdays.isEmpty) return true;
    final weekday = cycleStartUtc.toUtc().weekday;
    return activeWeekdays.contains(weekday);
  }
}
