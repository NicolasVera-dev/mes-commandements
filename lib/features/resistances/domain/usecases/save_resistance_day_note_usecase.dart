import '../entities/resistance_day_note.dart';
import '../repositories/resistance_day_note_repository.dart';

class SaveResistanceDayNoteUseCase {
  final ResistanceDayNoteRepository _repository;

  const SaveResistanceDayNoteUseCase(this._repository);

  Future<void> execute({
    required String resistanceId,
    required String dayKey,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.length > ResistanceDayNote.maxContentLength) {
      throw ArgumentError(
        'La note ne peut pas dépasser ${ResistanceDayNote.maxContentLength} caractères.',
      );
    }
    if (trimmed.isEmpty) {
      await _repository.deleteNote(
        resistanceId: resistanceId,
        dayKey: dayKey,
      );
      return;
    }
    await _repository.saveNote(
      ResistanceDayNote(
        resistanceId: resistanceId,
        dayKey: dayKey,
        content: trimmed,
        updatedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }
}
