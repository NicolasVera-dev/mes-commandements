import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../domain/entities/auto_reset_report.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_position_update.dart';
import '../../domain/repositories/command_repository.dart';

class CommandProvider extends ChangeNotifier {
  final CommandRepository _repository;
  late StreamSubscription<List<Command>> _subscription;
  List<Command> _commands = <Command>[];
  String _searchQuery = '';
  bool _isInitialLoading = true;
  bool _isMutating = false;
  String? _syncErrorMessage;

  CommandProvider({
    required CommandRepository repository,
  }) : _repository = repository {
    _listenToRepository();
  }

  bool get isInitialLoading => _isInitialLoading;
  bool get isMutating => _isMutating;
  String? get syncErrorMessage => _syncErrorMessage;

  void _listenToRepository() {
    _syncErrorMessage = null;
    _isInitialLoading = true;

    _subscription = _repository.watchAll().listen(
      (commands) {
        _commands = List<Command>.from(commands);
        _isInitialLoading = false;
        _syncErrorMessage = null;
        notifyListeners();
      },
      onError: (Object error, StackTrace st) {
        debugPrint('Erreur de synchronisation Firestore: $error');
        debugPrint('$st');
        // On évite d'afficher de potentielles données obsolètes.
        _commands = <Command>[];
        _isInitialLoading = false;
        _syncErrorMessage =
            'Une erreur est survenue lors de la synchronisation.';
        notifyListeners();
      },
    );
  }

  /// Déclenche silencieusement l'application des resets automatiques en batch.
  /// Ne bloque pas l'UI et n'affiche pas d'erreur utilisateur.
  Future<AutoResetReport> applyPendingAutoResetsSilently() async {
    try {
      return await _repository.applyPendingAutoResets(DateTime.now().toUtc());
    } catch (error, st) {
      debugPrint('Erreur reset automatique batch: $error');
      debugPrint('$st');
      return const AutoResetReport.empty();
    }
  }

  Future<void> retrySync() async {
    await _subscription.cancel();
    _listenToRepository();
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    // Une seule mutation à la fois pour garder l'UI stable.
    if (_isMutating) return;
    _isMutating = true;
    _syncErrorMessage = null;
    notifyListeners();

    try {
      await mutation();
    } catch (e, st) {
      debugPrint('Erreur mutation Firestore: $e');
      debugPrint('$st');
      _syncErrorMessage =
          'Une erreur est survenue lors de la modification.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  List<Command> get commands => List.unmodifiable(_commands);
  List<String> get availableTags {
    final set = <String>{};
    for (final command in _commands) {
      set.addAll(command.tags);
    }
    final list = set.toList(growable: false)..sort();
    return list;
  }

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
    unawaited(
      _runMutation(() => _repository.add(command)),
    );
  }

  void updateCommand(Command updatedCommand) {
    unawaited(
      _runMutation(() => _repository.update(updatedCommand)),
    );
  }

  void deleteCommand(String id) {
    unawaited(
      _runMutation(() => _repository.delete(id)),
    );
  }

  void incrementProgress(String commandId) {
    final command = getById(commandId);
    if (command == null) return;

    unawaited(
      _runMutation(() => _repository.incrementProgress(commandId)),
    );
  }

  void resetProgress(String commandId) {
    final command = getById(commandId);
    if (command == null) return;

    unawaited(
      _runMutation(() => _repository.resetProgress(commandId)),
    );
  }

  Future<void> reorderCommands({
    required int oldIndex,
    required int newIndex,
    required List<Command> visibleCommands,
  }) async {
    if (oldIndex < 0 ||
        oldIndex >= visibleCommands.length ||
        newIndex < 0 ||
        newIndex > visibleCommands.length) {
      return;
    }

    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjustedNewIndex == oldIndex) return;

    final visibleIds = visibleCommands.map((c) => c.id).toSet();
    final reorderedVisible = List<Command>.from(visibleCommands);
    final moved = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(adjustedNewIndex, moved);

    // Optimistic UI: réapplique le nouvel ordre sur la liste locale complète.
    final others = _commands.where((c) => !visibleIds.contains(c.id)).toList();
    final reindexedVisible = <Command>[];
    for (var i = 0; i < reorderedVisible.length; i++) {
      reindexedVisible.add(reorderedVisible[i].copyWith(position: i));
    }
    _commands = <Command>[...reindexedVisible, ...others];
    notifyListeners();

    final updates = <CommandPositionUpdate>[
      for (var i = 0; i < reorderedVisible.length; i++)
        CommandPositionUpdate(commandId: reorderedVisible[i].id, position: i),
    ];

    try {
      await _repository.updatePositions(updates);
    } catch (e, st) {
      debugPrint('Erreur reorder Firestore: $e');
      debugPrint('$st');
      _syncErrorMessage =
          'Le nouvel ordre n’a pas pu être synchronisé pour le moment.';
      notifyListeners();
      await retrySync();
    }
  }

  List<Command> commandsByFrequency(Frequency frequency) {
    return commandsFilteredSorted(
      frequencies: {frequency},
      statuses: const {},
      tags: const {},
      sort: CommandSort.alpha,
    );
  }

  List<Command> commandsFilteredSorted({
    /// null => "Toutes" (no frequency filtering).
    required Set<Frequency>? frequencies,
    /// empty => "Tous" (no status filtering).
    required Set<CommandStatusFilter> statuses,
    /// empty => no tag filtering.
    required Set<String> tags,
    required CommandSort sort,
  }) {
    final q = _searchQuery.toLowerCase();

    final List<Command> filtered = _commands
        .where((c) => frequencies == null ? true : frequencies.contains(c.frequency))
        .where((c) => statuses.isEmpty ? true : statuses.contains(_statusOf(c)))
        .where((c) => tags.isEmpty ? true : c.tags.any(tags.contains))
        .where((c) => q.isEmpty ? true : c.title.toLowerCase().contains(q))
        .toList(growable: false);

    double ratio(Command c) => c.target <= 0 ? 0.0 : c.progress / c.target;

    filtered.sort((a, b) {
      final aAlpha = a.title.toLowerCase();
      final bAlpha = b.title.toLowerCase();

      switch (sort) {
        case CommandSort.alpha:
          return (a.position == b.position)
              ? aAlpha.compareTo(bAlpha)
              : a.position.compareTo(b.position);
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

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
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

