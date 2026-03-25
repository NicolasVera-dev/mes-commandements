import 'package:flutter/foundation.dart';

import '../../domain/entities/command.dart';

class CommandProvider extends ChangeNotifier {
  final List<Command> _commands;
  String _searchQuery = '';

  CommandProvider({
    List<Command>? commands,
  }) : _commands = List<Command>.from(commands ?? <Command>[]);

  List<Command> get commands => List.unmodifiable(_commands);

  String get searchQuery => _searchQuery;

  /// Définit la requête de recherche.
  /// Le filtrage est appliqué dans `commandsFilteredSorted`.
  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized == _searchQuery) return;
    _searchQuery = normalized;
    notifyListeners();
  }

  Command? getById(String id) {
    try {
      return _commands.firstWhere((c) => c.id == id);
    } on StateError {
      return null;
    }
  }

  void addCommand(Command command) {
    _commands.add(command);
    notifyListeners();
  }

  void updateCommand(Command updatedCommand) {
    final idx = _commands.indexWhere((c) => c.id == updatedCommand.id);
    if (idx == -1) return;

    _commands[idx] = updatedCommand;
    notifyListeners();
  }

  void deleteCommand(String id) {
    _commands.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  void incrementProgress(String commandId) {
    final command = getById(commandId);
    if (command == null) return;

    updateCommand(command.incrementProgress());
  }

  void resetProgress(String commandId) {
    final command = getById(commandId);
    if (command == null) return;

    updateCommand(command.resetProgress());
  }

  List<Command> commandsByFrequency(Frequency frequency) {
    return commandsFilteredSorted(
      frequencies: {frequency},
      statuses: const {},
      sort: CommandSort.alpha,
    );
  }

  List<Command> commandsFilteredSorted({
    /// null => "Toutes" (no frequency filtering).
    required Set<Frequency>? frequencies,
    /// empty => "Tous" (no status filtering).
    required Set<CommandStatusFilter> statuses,
    required CommandSort sort,
  }) {
    final q = _searchQuery.toLowerCase();

    final List<Command> filtered = _commands
        .where((c) => frequencies == null ? true : frequencies.contains(c.frequency))
        .where((c) => statuses.isEmpty ? true : statuses.contains(_statusOf(c)))
        .where((c) => q.isEmpty ? true : c.title.toLowerCase().contains(q))
        .toList(growable: false);

    double ratio(Command c) => c.target <= 0 ? 0.0 : c.progress / c.target;

    filtered.sort((a, b) {
      final aAlpha = a.title.toLowerCase();
      final bAlpha = b.title.toLowerCase();

      switch (sort) {
        case CommandSort.alpha:
          return aAlpha.compareTo(bAlpha);
        case CommandSort.completedFirst:
          return (a.isCompleted() == b.isCompleted())
              ? aAlpha.compareTo(bAlpha)
              : (a.isCompleted() ? -1 : 1);
        case CommandSort.notCompletedFirst:
          return (a.isCompleted() == b.isCompleted())
              ? aAlpha.compareTo(bAlpha)
              : (a.isCompleted() ? 1 : -1);
        case CommandSort.highestProgressFirst:
          final aR = ratio(a);
          final bR = ratio(b);
          return (aR == bR) ? aAlpha.compareTo(bAlpha) : bR.compareTo(aR);
        case CommandSort.lowestProgressFirst:
          final aR = ratio(a);
          final bR = ratio(b);
          return (aR == bR) ? aAlpha.compareTo(bAlpha) : aR.compareTo(bR);
      }
    });

    return filtered;
  }

  CommandStatusFilter _statusOf(Command command) {
    if (command.isCompleted()) return CommandStatusFilter.completed;
    if (command.isStarted()) return CommandStatusFilter.started;
    return CommandStatusFilter.notStarted;
  }
}

enum CommandStatusFilter {
  all,
  notStarted,
  started,
  completed,
}

enum CommandSort {
  alpha,
  completedFirst,
  notCompletedFirst,
  highestProgressFirst,
  lowestProgressFirst,
}

