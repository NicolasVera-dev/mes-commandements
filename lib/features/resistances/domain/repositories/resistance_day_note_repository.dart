import '../entities/resistance_day_note.dart';

abstract class ResistanceDayNoteRepository {
  Stream<Map<String, ResistanceDayNote>> watchNotes(
    String resistanceId, {
    required Set<String> dayKeys,
  });

  Future<void> saveNote(ResistanceDayNote note);

  Future<void> deleteNote({
    required String resistanceId,
    required String dayKey,
  });

  Future<void> deleteAllForResistance(String resistanceId);
}
