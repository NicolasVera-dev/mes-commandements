import 'package:meta/meta.dart';

import '../services/cycle_key_generator.dart';
import 'command.dart';

enum CommandEventType {
  increment,
  resetAuto,
  resetManual,
  complete,
}

@immutable
class CommandEvent {
  final CommandEventType type;
  final DateTime actionAtUtc;
  final int progressAfterAction;
  final int targetAtAction;
  final String cycleKey;

  const CommandEvent({
    required this.type,
    required this.actionAtUtc,
    required this.progressAfterAction,
    required this.targetAtAction,
    required this.cycleKey,
  });

  factory CommandEvent.fromCommandSnapshot({
    required CommandEventType type,
    required Command command,
    required DateTime actionAtUtc,
  }) {
    final atUtc = actionAtUtc.toUtc();
    return CommandEvent(
      type: type,
      actionAtUtc: atUtc,
      progressAfterAction: command.progress,
      targetAtAction: command.target,
      cycleKey: CycleKeyGenerator.forFrequency(
        frequency: command.frequency,
        atUtc: atUtc,
      ),
    );
  }
}
