import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/journal_day.dart';
import '../../domain/entities/journal_reflection.dart';
import '../../domain/entities/journal_task.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/services/journal_day_summary.dart';

class JournalProvider extends ChangeNotifier {
  final JournalRepository _repository;
  final DateTime Function() _clock;
  late final StreamSubscription<String?> _authSubscription;
  StreamSubscription<List<JournalTask>>? _tasksSubscription;
  StreamSubscription<List<JournalReflection>>? _reflectionsSubscription;
  final Set<String> _busy = {};
  List<JournalTask> _tasks = [];
  List<JournalReflection> _reflections = [];
  String? _userId;
  bool _disposed = false;
  bool _authLoading = true;
  bool _tasksLoading = false;
  bool _reflectionsLoading = false;
  bool _hasError = false;
  int _generation = 0;

  JournalProvider({
    required JournalRepository repository,
    required Stream<String?> userIds,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now {
    _authSubscription = userIds.distinct().listen(
      _bindUser,
      onError: (Object error) {
        _authLoading = false;
        _hasError = true;
        _emit();
      },
    );
  }

  JournalDay get today => JournalDay.fromDate(_clock());
  bool get isConnected => _userId != null;
  bool get isLoading => _authLoading || _tasksLoading || _reflectionsLoading;
  bool get hasError => _hasError;
  bool get isSaving => _busy.isNotEmpty;
  JournalDaySummary summary(JournalDay day) =>
      JournalDaySummary(tasks: _tasks, day: day);
  JournalReflection? reflection(JournalDay day) =>
      _reflections.where((r) => r.day == day).firstOrNull;

  void refreshDay() => _emit();
  void retry() => _bindUser(_userId);

  void _bindUser(String? uid) {
    final generation = ++_generation;
    unawaited(_tasksSubscription?.cancel());
    unawaited(_reflectionsSubscription?.cancel());
    _tasks = [];
    _reflections = [];
    _busy.clear();
    _userId = uid;
    _hasError = false;
    _authLoading = false;
    _tasksLoading = uid != null;
    _reflectionsLoading = uid != null;
    _emit();
    if (uid == null) return;
    void failed(Object error) {
      if (generation != _generation || _disposed) return;
      _hasError = true;
      _tasksLoading = false;
      _reflectionsLoading = false;
      _emit();
    }

    _tasksSubscription = _repository.watchTasks(uid).listen((tasks) {
      if (generation != _generation || _disposed) return;
      _tasks = tasks;
      _tasksLoading = false;
      _emit();
    }, onError: failed);
    _reflectionsSubscription = _repository.watchReflections(uid).listen((
      notes,
    ) {
      if (generation != _generation || _disposed) return;
      _reflections = notes;
      _reflectionsLoading = false;
      _emit();
    }, onError: failed);
  }

  Future<void> _write(String key, Future<void> Function(String) action) async {
    final uid = _userId;
    final generation = _generation;
    if (uid == null || isLoading || hasError || !_busy.add(key)) {
      throw StateError('Journal is not ready');
    }
    _emit();
    try {
      await action(uid);
    } finally {
      if (generation == _generation) {
        _busy.remove(key);
        _emit();
      }
    }
  }

  JournalTask _task(String id) => _tasks.firstWhere((t) => t.id == id);

  Future<void> add({
    required String title,
    required JournalDay day,
    bool priority = false,
  }) {
    if (day.isBefore(today)) throw ArgumentError('Cannot plan in the past');
    return _write('new', (uid) {
      final task = JournalTask(
        id: _repository.newTaskId(uid),
        title: title,
        plans: [JournalPlan(start: day)],
        priority: priority,
        order: _clock().microsecondsSinceEpoch.toDouble(),
      );
      return _repository.saveTask(uid, task);
    });
  }

  Future<void> toggle(String id, bool done) => _write(
    id,
    (uid) => _repository.saveTask(uid, _task(id).complete(today, done: done)),
  );

  Future<void> edit(
    String id, {
    required String title,
    required bool priority,
  }) => _write(id, (uid) {
    final task = _task(id);
    if (task.removedDay != null || task.completedDay != null) {
      throw StateError('Only open tasks can be edited');
    }
    return _repository.saveTask(
      uid,
      task.edit(title: title, priority: priority),
    );
  });

  Future<JournalTask> remove(String id) async {
    final task = _task(id);
    if (task.removedDay != null ||
        (task.completedDay != null && task.completedDay != today)) {
      throw StateError('Past days are read-only');
    }
    await _write(id, (uid) => _repository.saveTask(uid, task.remove(today)));
    return task;
  }

  Future<void> restore(JournalTask task) => _write(task.id, (uid) {
    final current = _task(task.id);
    if (current.removedDay != today) throw StateError('Undo has expired');
    return _repository.saveTask(uid, current.restore());
  });

  Future<void> reschedule(String id, JournalDay target) => _write(
    id,
    (uid) => _repository.saveTask(uid, _task(id).reschedule(target, today)),
  );

  Future<void> reorder(List<String> ids) => _write('order', (uid) {
    final tasks = [
      for (var i = 0; i < ids.length; i++)
        _task(ids[i]).edit(order: i.toDouble()),
    ];
    return _repository.reorder(uid, tasks);
  });

  Future<void> saveReflection(JournalReflection reflection) {
    if (reflection.day.isAfter(today)) throw ArgumentError('Future reflection');
    return _write(
      'reflection',
      (uid) => _repository.saveReflection(uid, reflection),
    );
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription.cancel();
    _tasksSubscription?.cancel();
    _reflectionsSubscription?.cancel();
    super.dispose();
  }
}
