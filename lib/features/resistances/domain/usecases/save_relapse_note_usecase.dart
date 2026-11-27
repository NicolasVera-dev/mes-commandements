import '../entities/resistance_relapse.dart';
import '../repositories/resistance_relapse_repository.dart';

class SaveRelapseNoteUseCase {
  final ResistanceRelapseRepository repository;
  const SaveRelapseNoteUseCase(this.repository);

  Future<void> execute({
    required String resistanceId,
    required String relapseId,
    required String note,
  }) {
    final content = note.trim();
    if (content.length > ResistanceRelapse.maxNoteLength)
      throw ArgumentError('Note too long');
    return repository.saveNote(
      resistanceId: resistanceId,
      relapseId: relapseId,
      note: content,
    );
  }
}
