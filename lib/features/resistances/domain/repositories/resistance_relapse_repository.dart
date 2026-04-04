import '../entities/resistance_relapse.dart';

abstract class ResistanceRelapseRepository {
  Stream<List<ResistanceRelapse>> watchRelapses(String resistanceId);
}
