import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/resistance_day_note.dart';
import '../../domain/repositories/resistance_day_note_repository.dart';
import '../../domain/usecases/save_resistance_day_note_usecase.dart';

class ResistanceDayNoteProvider extends ChangeNotifier {
  final ResistanceDayNoteRepository _repository;
  final SaveResistanceDayNoteUseCase _saveUseCase;

  Map<String, ResistanceDayNote> _notes = {};
  StreamSubscription<Map<String, ResistanceDayNote>>? _subscription;
  String? _subscribedResistanceId;
  Set<String> _subscribedKeys = {};
  bool _isSaving = false;

  ResistanceDayNoteProvider({
    required ResistanceDayNoteRepository repository,
    required SaveResistanceDayNoteUseCase saveUseCase,
  })  : _repository = repository,
        _saveUseCase = saveUseCase;

  Map<String, ResistanceDayNote> get notes =>
      Map<String, ResistanceDayNote>.unmodifiable(_notes);

  ResistanceDayNote? noteFor(String dayKey) => _notes[dayKey];

  bool get isSaving => _isSaving;

  void _scheduleNotify() {
    Future<void>.microtask(() {
      if (hasListeners) notifyListeners();
    });
  }

  void unsubscribe() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedResistanceId = null;
    _subscribedKeys = {};
    _notes = {};
    _scheduleNotify();
  }

  void subscribe({
    required String resistanceId,
    required Set<String> dayKeys,
  }) {
    final keys = Set<String>.from(dayKeys);
    if (_subscribedResistanceId == resistanceId &&
        _subscribedKeys.length == keys.length &&
        _subscribedKeys.containsAll(keys) &&
        keys.containsAll(_subscribedKeys)) {
      return;
    }

    unawaited(_subscription?.cancel());
    _subscription = null;
    _subscribedResistanceId = resistanceId;
    _subscribedKeys = keys;

    if (keys.isEmpty) {
      _notes = {};
      _scheduleNotify();
      return;
    }

    _subscription = _repository.watchNotes(resistanceId, dayKeys: keys).listen(
      (notes) {
        _notes = notes;
        _scheduleNotify();
      },
      onError: (Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'ResistanceDayNoteProvider',
          ),
        );
      },
    );
  }

  Future<void> saveNote({
    required String resistanceId,
    required String dayKey,
    required String content,
  }) async {
    _isSaving = true;
    notifyListeners();
    try {
      await _saveUseCase.execute(
        resistanceId: resistanceId,
        dayKey: dayKey,
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
