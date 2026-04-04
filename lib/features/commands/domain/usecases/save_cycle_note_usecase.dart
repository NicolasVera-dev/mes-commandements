import '../entities/cycle_note.dart';
import '../repositories/cycle_note_repository.dart';

class SaveCycleNoteUseCase {
  final CycleNoteRepository _repository;

  const SaveCycleNoteUseCase(this._repository);

  Future<void> execute({
    required String commandId,
    required String cycleKey,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.length > CycleNote.maxContentLength) {
      throw ArgumentError(
        'La note ne peut pas dépasser ${CycleNote.maxContentLength} caractères.',
      );
    }
    if (trimmed.isEmpty) {
      await _repository.deleteNote(
        commandId: commandId,
        cycleKey: cycleKey,
      );
      return;
    }
    await _repository.saveNote(
      CycleNote(
        commandId: commandId,
        cycleKey: cycleKey,
        content: trimmed,
        updatedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }
}
