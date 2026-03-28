import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

enum CycleStatus {
  success,
  failed,
  inProgress,
  hidden,
}

class EvaluateCycleStatusUseCase {
  const EvaluateCycleStatusUseCase();

  CycleStatus execute({
    required Frequency frequency,
    required DateTime cycleStartUtc,
    required DateTime createdAtUtc,
    required DateTime nowUtc,
    required List<CommandEvent> cycleEvents,
  }) {
    final cycleStart =
        CycleKeyGenerator.cycleStartUtc(frequency, cycleStartUtc.toUtc());
    final firstVisible =
        CycleKeyGenerator.cycleStartUtc(frequency, createdAtUtc.toUtc());
    if (cycleStart.isBefore(firstVisible)) {
      return CycleStatus.hidden;
    }

    final hasComplete = cycleEvents.any((e) => e.type == CommandEventType.complete);
    if (hasComplete) return CycleStatus.success;

    final currentStart =
        CycleKeyGenerator.cycleStartUtc(frequency, nowUtc.toUtc());
    if (cycleStart.isAtSameMomentAs(currentStart)) {
      return CycleStatus.inProgress;
    }
    if (cycleStart.isBefore(currentStart)) {
      return CycleStatus.failed;
    }
    return CycleStatus.inProgress;
  }
}
