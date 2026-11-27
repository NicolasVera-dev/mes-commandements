import '../entities/resistance_relapse.dart';

abstract class ResistanceRelapseRepository {
  Future<void> saveNote({
    required String resistanceId,
    required String relapseId,
    required String note,
  });

  Stream<List<ResistanceRelapse>> watchRelapses(String resistanceId);
}
