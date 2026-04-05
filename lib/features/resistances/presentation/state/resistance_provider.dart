import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/resistance.dart';
import '../../domain/entities/resistance_position_update.dart';
import '../../domain/repositories/resistance_repository.dart';
import '../../domain/usecases/compute_resistance_streak_usecase.dart';
import '../../domain/usecases/filter_and_sort_resistances_usecase.dart';
import '../../domain/usecases/record_resistance_relapse_usecase.dart';

class ResistanceProvider extends ChangeNotifier {
  final ResistanceRepository _repository;
  final RecordResistanceRelapseUseCase _recordRelapseUseCase;
  final FilterAndSortResistancesUseCase _filterAndSortUseCase;
  late StreamSubscription<List<Resistance>> _subscription;
  List<Resistance> _resistances = <Resistance>[];
  String _searchQuery = '';
  bool _isInitialLoading = true;
  bool _isMutating = false;
  final Set<String> _mutatingIds = <String>{};
  String? _syncErrorMessage;
  static const _streakUseCase = ComputeResistanceStreakUseCase();

  ResistanceProvider({
    required ResistanceRepository repository,
    required RecordResistanceRelapseUseCase recordRelapseUseCase,
    FilterAndSortResistancesUseCase? filterAndSortResistancesUseCase,
  })  : _repository = repository,
        _recordRelapseUseCase = recordRelapseUseCase,
        _filterAndSortUseCase = filterAndSortResistancesUseCase ??
            const FilterAndSortResistancesUseCase() {
    _listen();
  }

  bool get isInitialLoading => _isInitialLoading;
  bool get isMutating => _isMutating || _mutatingIds.isNotEmpty;
  String? get syncErrorMessage => _syncErrorMessage;

  void _listen() {
    _syncErrorMessage = null;
    _isInitialLoading = true;
    _subscription = _repository.watchAll().listen(
      (list) {
        _resistances = List<Resistance>.from(list);
        _isInitialLoading = false;
        _syncErrorMessage = null;
        notifyListeners();
        unawaited(_syncBestStreaksIfNeeded(list));
      },
      onError: (Object error, StackTrace st) {
        if (kDebugMode) {
          debugPrint('Erreur sync résistances: $error');
          debugPrint('$st');
        }
        _resistances = <Resistance>[];
        _isInitialLoading = false;
        _syncErrorMessage =
            'Une erreur est survenue lors de la synchronisation.';
        notifyListeners();
      },
    );
  }

  /// Met à jour `bestStreakDays` côté serveur lorsque le streak courant le dépasse
  /// (sans attendre une rechute).
  Future<void> _syncBestStreaksIfNeeded(List<Resistance> list) async {
    final now = DateTime.now().toUtc();
    for (final r in list) {
      if (_mutatingIds.contains(r.id)) continue;
      final streak = _streakUseCase.execute(resistance: r, nowUtc: now);
      if (streak <= r.bestStreakDays) continue;
      try {
        await _repository.update(r.copyWith(bestStreakDays: streak));
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('Sync bestStreakDays (${r.id}): $e');
          debugPrint('$st');
        }
      }
    }
  }

  Future<void> retrySync() async {
    await _subscription.cancel();
    _listen();
  }

  Future<void> _runMutation(Future<void> Function() mutation) async {
    if (_isMutating) return;
    _isMutating = true;
    _syncErrorMessage = null;
    notifyListeners();
    try {
      await mutation();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Erreur mutation résistance: $e');
        debugPrint('$st');
      }
      _syncErrorMessage =
          'Une erreur est survenue lors de la modification.';
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  Future<void> _runMutationForId(
    String id,
    Future<void> Function() mutation,
  ) async {
    if (_mutatingIds.contains(id)) return;
    _mutatingIds.add(id);
    _syncErrorMessage = null;
    notifyListeners();
    try {
      await mutation();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Erreur mutation résistance: $e');
        debugPrint('$st');
      }
      _syncErrorMessage =
          'Une erreur est survenue lors de la modification.';
    } finally {
      _mutatingIds.remove(id);
      notifyListeners();
    }
  }

  List<Resistance> get resistances => List.unmodifiable(_resistances);

  List<String> get availableTags {
    final set = <String>{};
    for (final r in _resistances) {
      set.addAll(r.tags);
    }
    final list = set.toList(growable: false)..sort();
    return list;
  }

  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    final normalized = query.trim();
    if (normalized == _searchQuery) return;
    _searchQuery = normalized;
    notifyListeners();
  }

  List<Resistance> resistancesFilteredSorted({
    required Set<String> tags,
    required ResistanceSort sort,
  }) {
    return _filterAndSortUseCase.execute(
      resistances: _resistances,
      tags: tags,
      sort: sort,
      searchQuery: _searchQuery,
      nowUtc: DateTime.now().toUtc(),
    );
  }

  Resistance? getById(String id) {
    try {
      return _resistances.firstWhere((r) => r.id == id);
    } on StateError {
      return null;
    }
  }

  void addResistance(Resistance resistance) {
    unawaited(_runMutation(() => _repository.add(resistance)));
  }

  void updateResistance(Resistance resistance) {
    unawaited(_runMutation(() => _repository.update(resistance)));
  }

  void deleteResistance(String id) {
    unawaited(_runMutationForId(id, () => _repository.delete(id)));
  }

  Future<void> recordRelapse({
    required String resistanceId,
    String? note,
  }) async {
    final r = getById(resistanceId);
    if (r == null) return;
    await _runMutationForId(
      resistanceId,
      () => _recordRelapseUseCase.execute(
            resistance: r,
            relapsedAtUtc: DateTime.now().toUtc(),
            note: note,
          ),
    );
  }

  Future<void> reorderResistances({
    required int oldIndex,
    required int newIndex,
    required List<Resistance> visible,
  }) async {
    if (oldIndex < 0 ||
        oldIndex >= visible.length ||
        newIndex < 0 ||
        newIndex > visible.length) {
      return;
    }
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjusted == oldIndex) return;

    final visibleIds = visible.map((r) => r.id).toSet();
    final reordered = List<Resistance>.from(visible);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjusted, moved);

    final others = _resistances.where((r) => !visibleIds.contains(r.id)).toList();
    final reindexed = <Resistance>[];
    for (var i = 0; i < reordered.length; i++) {
      reindexed.add(reordered[i].copyWith(position: i));
    }
    _resistances = <Resistance>[...reindexed, ...others];
    notifyListeners();

    final updates = <ResistancePositionUpdate>[
      for (var i = 0; i < reordered.length; i++)
        ResistancePositionUpdate(
          resistanceId: reordered[i].id,
          position: i,
        ),
    ];

    try {
      await _repository.updatePositions(updates);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('Erreur reorder résistances: $e');
        debugPrint('$st');
      }
      _syncErrorMessage =
          'Le nouvel ordre n’a pas pu être synchronisé pour le moment.';
      notifyListeners();
      await retrySync();
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
