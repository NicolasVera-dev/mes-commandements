import '../entities/journal_day.dart';
import '../entities/journal_task.dart';

class JournalDaySummary {
  final List<JournalTask> tasks;
  final JournalDay day;

  JournalDaySummary({required Iterable<JournalTask> tasks, required this.day})
    : tasks = List.unmodifiable(
        tasks.where((t) => t.appearsOn(day)).toList()..sort((a, b) {
          final result = a.order.compareTo(b.order);
          return result == 0 ? a.id.compareTo(b.id) : result;
        }),
      );

  List<JournalTask> get completed =>
      tasks.where((t) => t.completedOn(day)).toList();
  List<JournalTask> get pending =>
      tasks.where((t) => !t.completedOn(day)).toList();
  int? get score =>
      tasks.isEmpty ? null : (completed.length / tasks.length * 100).round();
}
