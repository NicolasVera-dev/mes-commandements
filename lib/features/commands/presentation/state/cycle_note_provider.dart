import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/cycle_note.dart';
import '../../domain/repositories/cycle_note_repository.dart';
import '../../domain/usecases/save_cycle_note_usecase.dart';

class CycleNoteProvider extends ChangeNotifier {
  final CycleNoteRepository _repository;
  final SaveCycleNoteUseCase _saveUseCase;

  Map<String, CycleNote> _notes = {};
  StreamSubscription<Map<String, CycleNote>>? _subscription;
  String? _subscribedCommandId;
  Set<String> _subscribedKeys = {};
  bool _isSaving = false;

  CycleNoteProvider({
    required CycleNoteRepository repository,
    required SaveCycleNoteUseCase saveUseCase,
  })  : _repository = repository,
        _saveUseCase = saveUseCase;

  Map<String, CycleNote> get notes => Map<String, CycleNote>.unmodifiable(_notes);

  CycleNote? noteFor(String cycleKey) => _notes[cycleKey];

  bool get isSaving => _isSaving;

  void _scheduleNotify() {
    Future<void>.microtask(() {
      if (hasListeners) notifyListeners();
    });
  }

  void unsubscribe() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedCommandId = null;
    _subscribedKeys = {};
    _notes = {};
    _scheduleNotify();
  }

  /// S’abonne aux notes pour un commandement et un ensemble fixe de cycles affichés.
  void subscribe({
    required String commandId,
    required Set<String> cycleKeys,
  }) {
    final keys = Set<String>.from(cycleKeys);
    if (_subscribedCommandId == commandId &&
        _subscribedKeys.length == keys.length &&
        _subscribedKeys.containsAll(keys) &&
        keys.containsAll(_subscribedKeys)) {
      return;
    }

    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedCommandId = commandId;
    _subscribedKeys = keys;

    if (keys.isEmpty) {
      _notes = {};
      _scheduleNotify();
      return;
    }

    _subscription = _repository.watchNotes(commandId, cycleKeys: keys).listen(
      (notes) {
        _notes = notes;
        _scheduleNotify();
      },
      onError: (Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'CycleNoteProvider',
          ),
        );
      },
    );
  }

  Future<void> saveNote({
    required String commandId,
    required String cycleKey,
    required String content,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _saveUseCase.execute(
        commandId: commandId,
        cycleKey: cycleKey,
        content: content,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
