import '../entities/journal_task.dart';
import '../entities/journal_reflection.dart';

abstract class JournalRepository {
  String newTaskId(String userId);
  Stream<List<JournalTask>> watchTasks(String userId);
  Stream<List<JournalReflection>> watchReflections(String userId);
  Future<void> saveTask(String userId, JournalTask task);
  Future<void> reorder(String userId, List<JournalTask> tasks);
  Future<void> saveReflection(String userId, JournalReflection reflection);
}
