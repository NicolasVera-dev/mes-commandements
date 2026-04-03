import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/repositories/command_event_repository.dart';
import '../../domain/usecases/compute_streak_usecase.dart';
import 'command_streak_badge.dart';

/// Charge l’historique via [CommandEventRepository.watchEventsFrom] et affiche le badge de série.
class CommandStreakFromRepository extends StatefulWidget {
  const CommandStreakFromRepository({
    super.key,
    required this.command,
    required this.compact,
    this.titleIndent = 0,
  });

  final Command command;
  final bool compact;

  /// Décalage à gauche pour aligner le pill sous le titre (ex. largeur emoji + gap).
  final double titleIndent;

  @override
  State<CommandStreakFromRepository> createState() =>
      _CommandStreakFromRepositoryState();
}

class _CommandStreakFromRepositoryState extends State<CommandStreakFromRepository> {
  Stream<List<CommandEvent>>? _eventsStream;
  String? _streamForCommandId;
  DateTime? _streamForStartUtc;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final start =
        widget.command.createdAt?.toUtc() ?? DateTime.utc(2000, 1, 1);
    final id = widget.command.id;
    if (_eventsStream == null ||
        _streamForCommandId != id ||
        _streamForStartUtc != start) {
      _streamForCommandId = id;
      _streamForStartUtc = start;
      _eventsStream = context.read<CommandEventRepository>().watchEventsFrom(
            id,
            startUtcInclusive: start,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _eventsStream;
    if (stream == null) {
      return const SizedBox.shrink();
    }
    final effectiveCreated =
        widget.command.createdAt?.toUtc() ?? DateTime.utc(2000, 1, 1);

    return StreamBuilder<List<CommandEvent>>(
      stream: stream,
      initialData: const <CommandEvent>[],
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final events = snapshot.data ?? const <CommandEvent>[];
        final grouped = groupCommandEventsByCycle(events);
        final result = const ComputeStreakUseCase().execute(
          command: widget.command,
          grouped: grouped,
          createdAtUtc: effectiveCreated,
        );
        return Padding(
          padding: EdgeInsets.only(left: widget.titleIndent),
          child: CommandStreakBadge(
            result: result,
            frequency: widget.command.frequency,
            compact: widget.compact,
          ),
        );
      },
    );
  }
}

Map<String, List<CommandEvent>> groupCommandEventsByCycle(
  List<CommandEvent> events,
) {
  final map = <String, List<CommandEvent>>{};
  for (final event in events) {
    map.putIfAbsent(event.cycleKey, () => <CommandEvent>[]).add(event);
  }
  return map;
}
