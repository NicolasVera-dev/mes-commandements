import '../entities/cycle_note.dart';

abstract class CycleNoteRepository {
  /// Stream temps réel des notes pour les [cycleKeys] demandés (clé = cycleKey).
  Stream<Map<String, CycleNote>> watchNotes(
    String commandId, {
    required Set<String> cycleKeys,
  });

  Future<void> saveNote(CycleNote note);

  Future<void> deleteNote({
    required String commandId,
    required String cycleKey,
  });

  Future<void> deleteAllNotes(String commandId);
}
