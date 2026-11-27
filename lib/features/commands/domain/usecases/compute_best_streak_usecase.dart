import '../entities/command.dart';
import '../entities/command_event.dart';
import '../services/cycle_key_generator.dart';

/// Longest successful series across the full history, with the same neutral
/// inactive/paused cycles as the current streak. An unfinished current cycle
/// never erases a record.
class ComputeBestStreakUseCase {
  const ComputeBestStreakUseCase();

  int execute({
    required Command command,
    required Map<String, List<CommandEvent>> grouped,
    required DateTime createdAtUtc,
    DateTime? nowUtc,
  }) {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    if (now.isBefore(createdAtUtc)) return 0;
    final current = CycleKeyGenerator.cycleStartUtc(command.frequency, now);
    var best = 0;
    var run = 0;
    for (
      var cycle = CycleKeyGenerator.cycleStartUtc(
        command.frequency,
        createdAtUtc,
      );
      !cycle.isAfter(current);
      cycle = CycleKeyGenerator.nextCycleStartUtc(command.frequency, cycle)
    ) {
      if (!command.isActiveOnDayUtc(cycle)) continue;
      final complete =
          grouped[command.cycleKeyAt(cycle)]?.any(
            (e) => e.type == CommandEventType.complete,
          ) ??
          false;
      final currentProgress =
          cycle == current &&
          command.isCompleted() &&
          !(command.lastResetAt ?? createdAtUtc).isBefore(current);
      if (complete || currentProgress) {
        run++;
        if (run > best) best = run;
      } else if (cycle != current && !command.wasPausedAtCycleEnd(cycle)) {
        run = 0;
      }
    }
    return best;
  }
}
