import '../entities/resistance.dart';
import '../entities/resistance_position_update.dart';

abstract class ResistanceRepository {
  Stream<List<Resistance>> watchAll();

  Future<void> add(Resistance resistance);

  Future<void> update(Resistance resistance);

  Future<void> delete(String resistanceId);

  Future<void> updatePositions(List<ResistancePositionUpdate> updates);

  /// Enregistre une rechute et met à jour `lastRelapseAtUtc` + `bestStreakDays`.
  Future<void> recordRelapse({
    required String resistanceId,
    required DateTime relapsedAtUtc,
    required int previousStreakDays,
    required int newBestStreakDays,
    String? note,
  });
}
