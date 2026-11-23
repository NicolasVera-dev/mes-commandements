import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../notifications/domain/notification_scheduler.dart';
import '../../domain/entities/auto_reset_report.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_position_update.dart';
import '../../domain/repositories/command_repository.dart';
import '../../domain/usecases/filter_and_sort_commands_usecase.dart';

class CommandProvider extends ChangeNotifier {
  final CommandRepository _repository;
  final FilterAndSortCommandsUseCase _filterAndSortCommandsUseCase;
  final NotificationScheduler _notificationScheduler;
  late StreamSubscription<List<Command>> _subscription;
  Timer? _pauseTimer;
  List<Command> _commands = <Command>[];
  String _searchQuery = '';
  bool _isInitialLoading = true;
  bool _isMutating = false;
  final Set<String> _mutatingIds = <String>{};
  String? _syncErrorMessage;
  bool _hasReceivedFirstCommandSnapshot = false;
  bool _notificationReschedulePending = false;

  CommandProvider({
    required CommandRepository repository,
    FilterAndSortCommandsUseCase? filterAndSortCommandsUseCase,
    NotificationScheduler? notificationScheduler,
  }) : _repository = repository,
       _filterAndSortCommandsUseCase =
           filterAndSortCommandsUseCase ?? const FilterAndSortCommandsUseCase(),
       _notificationScheduler =
           notificationScheduler ?? const NoOpNotificationScheduler() {
    _listenToRepository();
  }

  bool get isInitialLoading => _isInitialLoading;
  bool get isMutating => _isMutating || _mutatingIds.isNotEmpty;
  String? get syncErrorMessage => _syncErrorMessage;

  void _listenToRepository() {
    _syncErrorMessage = null;
    _isInitialLoading = true;

    _subscription = _repository.watchAll().listen(
      (commands) {
        final previousById = {
          for (final command in _commands) command.id: command,
        };
        final pauseChanged = commands.any((command) {
          final previous = previousById[command.id];
          return previous != null &&
              (previous.pauses.length != command.pauses.length ||
                  previous.pauses.lastOrNull != command.pauses.lastOrNull);
        });
        _commands = List<Command>.from(commands);
        _schedulePauseEnd();
        _isInitialLoading = false;
        _syncErrorMessage = null;

        var shouldReschedule = false;
        if (!_hasReceivedFirstCommandSnapshot) {
          _hasReceivedFirstCommandSnapshot = true;
          shouldReschedule = true;
        } else if (_notificationReschedulePending) {
          _notificationReschedulePending = false;
          shouldReschedule = true;
        }
        if (shouldReschedule || pauseChanged) {
          unawaited(_notificationScheduler.rescheduleAll(_commands));
        }

        notifyListeners();
      },
      onError: (Object error, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Erreur de synchronisation Firestore: $error');
          debugPrint('$st');
        }
        // On évite d'afficher de potentielles données obsolètes.
        _commands = <Command>[];
        _pauseTimer?.cancel();
        _isInitialLoading = false;
        _hasReceivedFirstCommandSnapshot = false;
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
      if (kDebugMode) {
        debugPrint('Erreur reset automatique batch: $error');
        debugPrint('$st');
      }
      return const AutoResetReport.empty();
    }
  }

  Future<void> retrySync() async {
    await _subscription.cancel();
    _hasReceivedFirstCommandSnapshot = false;
    _listenToRepository();
  }

  void _markCommandsChangedForNotifications() {
    _notificationReschedulePending = true;
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
      if (kDebugMode) {
        debugPrint('Erreur mutation Firestore: $e');
        debugPrint('$st');
      }
      _syncErrorMessage = 'Une erreur est survenue lors de la modification.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<bool> _runMutationForId(
    String commandId,
    Future<void> Function() mutation,
  ) async {
    if (_mutatingIds.contains(commandId)) return false;
    _mutatingIds.add(commandId);
    _syncErrorMessage = null;
    notifyListeners();

    try {
      await mutation();
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Erreur mutation Firestore: $e');
        debugPrint('$st');
      }
      _syncErrorMessage = 'Une erreur est survenue lors de la modification.';
      return false;
    } finally {
      _mutatingIds.remove(commandId);
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
    _markCommandsChangedForNotifications();
    unawaited(_runMutation(() => _repository.add(command)));
  }

  void updateCommand(Command updatedCommand) {
    _markCommandsChangedForNotifications();
    unawaited(_runMutation(() => _repository.update(updatedCommand)));
  }

  Future<bool> deleteCommand(String id) {
    _markCommandsChangedForNotifications();
    return _runMutationForId(id, () => _repository.delete(id));
  }

  Future<void> pauseCommand(String id, {DateTime? untilUtc}) =>
      _runMutationForId(id, () => _repository.pause(id, untilUtc: untilUtc));

  Future<void> resumeCommand(String id, {required bool nextCycle}) =>
      _runMutationForId(id, () => _repository.resume(id, nextCycle: nextCycle));

  void _schedulePauseEnd() {
    _pauseTimer?.cancel();
    final now = DateTime.now().toUtc();
    DateTime? firstEnd;
    for (final command in _commands) {
      final end = command.pauseAt(now)?.endUtc;
      if (end != null && (firstEnd == null || end.isBefore(firstEnd))) {
        firstEnd = end;
      }
    }
    if (firstEnd == null) return;
    _pauseTimer = Timer(firstEnd.difference(now), refreshAfterPause);
  }

  void refreshAfterPause() {
    if (!_commands.any((command) => command.pauses.isNotEmpty)) return;
    _schedulePauseEnd();
    _markCommandsChangedForNotifications();
    notifyListeners();
    unawaited(_refreshPauseReminders());
  }

  Future<void> _refreshPauseReminders() async {
    final report = await applyPendingAutoResetsSilently();
    if (!report.hasResets) {
      await _notificationScheduler.rescheduleAll(_commands);
    }
  }

  void incrementProgress(String commandId) {
    final command = getById(commandId);
    if (command == null || command.isPausedAt(DateTime.now())) return;

    _markCommandsChangedForNotifications();
    unawaited(
      _runMutationForId(
        commandId,
        () => _repository.incrementProgress(commandId),
      ),
    );
  }

  Future<bool> resetProgress(String commandId) async {
    final command = getById(commandId);
    if (command == null || command.isPausedAt(DateTime.now())) return false;

    _markCommandsChangedForNotifications();
    return _runMutationForId(
      commandId,
      () => _repository.resetProgress(commandId),
    );
  }

  void completePastCycle({
    required String commandId,
    required String cycleKey,
  }) {
    final command = getById(commandId);
    if (command == null) return;

    _markCommandsChangedForNotifications();
    unawaited(
      _runMutationForId(
        commandId,
        () => _repository.completePastCycle(
          commandId: commandId,
          cycleKey: cycleKey,
        ),
      ),
    );
  }

  void uncompletePastCycle({
    required String commandId,
    required String cycleKey,
  }) {
    final command = getById(commandId);
    if (command == null) return;

    _markCommandsChangedForNotifications();
    unawaited(
      _runMutationForId(
        commandId,
        () => _repository.uncompletePastCycle(
          commandId: commandId,
          cycleKey: cycleKey,
        ),
      ),
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
        newIndex >= visibleCommands.length) {
      return;
    }

    if (newIndex == oldIndex) return;

    final visibleIds = visibleCommands.map((c) => c.id).toSet();
    final reorderedVisible = List<Command>.from(visibleCommands);
    final moved = reorderedVisible.removeAt(oldIndex);
    reorderedVisible.insert(newIndex, moved);

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
      if (kDebugMode) {
        debugPrint('Erreur reorder Firestore: $e');
        debugPrint('$st');
      }
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
    return _filterAndSortCommandsUseCase.execute(
      commands: _commands,
      frequencies: frequencies,
      statuses: statuses,
      tags: tags,
      sort: sort,
      searchQuery: _searchQuery,
    );
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
