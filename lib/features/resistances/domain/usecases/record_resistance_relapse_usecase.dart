import '../entities/resistance.dart';
import '../entities/resistance_relapse.dart';
import '../repositories/resistance_repository.dart';
import 'compute_resistance_streak_usecase.dart';

class RecordResistanceRelapseUseCase {
  final ResistanceRepository _repository;
  final ComputeResistanceStreakUseCase _streakUseCase;

  const RecordResistanceRelapseUseCase(
    this._repository, [
    ComputeResistanceStreakUseCase? streakUseCase,
  ]) : _streakUseCase = streakUseCase ?? const ComputeResistanceStreakUseCase();

  Future<void> execute({
    required Resistance resistance,
    required DateTime relapsedAtUtc,
    String? note,
  }) async {
    final trimmed = note?.trim();
    if (trimmed != null && trimmed.length > ResistanceRelapse.maxNoteLength) {
      throw ArgumentError(
        'La note ne peut pas dépasser ${ResistanceRelapse.maxNoteLength} caractères.',
      );
    }

    final atUtc = relapsedAtUtc.toUtc();
    final previous = _streakUseCase.execute(resistance: resistance, nowUtc: atUtc);
    final newBest = previous > resistance.bestStreakDays
        ? previous
        : resistance.bestStreakDays;

    await _repository.recordRelapse(
      resistanceId: resistance.id,
      relapsedAtUtc: atUtc,
      previousStreakDays: previous,
      newBestStreakDays: newBest,
      note: trimmed?.isEmpty ?? true ? null : trimmed,
    );
  }
}
