import '../entities/command.dart';
import '../entities/command_event.dart';

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
    final cycleStart = _cycleStartUtc(frequency, cycleStartUtc.toUtc());
    final firstVisible = _cycleStartUtc(frequency, createdAtUtc.toUtc());
    if (cycleStart.isBefore(firstVisible)) {
      return CycleStatus.hidden;
    }

    final hasComplete = cycleEvents.any((e) => e.type == CommandEventType.complete);
    if (hasComplete) return CycleStatus.success;

    final currentStart = _cycleStartUtc(frequency, nowUtc.toUtc());
    if (cycleStart.isAtSameMomentAs(currentStart)) {
      return CycleStatus.inProgress;
    }
    if (cycleStart.isBefore(currentStart)) {
      return CycleStatus.failed;
    }
    return CycleStatus.inProgress;
  }

  DateTime _cycleStartUtc(Frequency frequency, DateTime dateUtc) {
    switch (frequency) {
      case Frequency.daily:
        return DateTime.utc(dateUtc.year, dateUtc.month, dateUtc.day);
      case Frequency.weekly:
        final deltaFromMonday = dateUtc.weekday - DateTime.monday;
        final monday = dateUtc.subtract(Duration(days: deltaFromMonday));
        return DateTime.utc(monday.year, monday.month, monday.day);
      case Frequency.monthly:
        return DateTime.utc(dateUtc.year, dateUtc.month, 1);
      case Frequency.yearly:
        return DateTime.utc(dateUtc.year, 1, 1);
    }
  }
}
