import '../entities/journal_day.dart';
import 'journal_day_summary.dart';

enum JournalDayStatus { empty, planned, inProgress, success, failure }

JournalDayStatus journalDayStatus(JournalDaySummary summary, JournalDay today) {
  if (summary.tasks.isEmpty) return JournalDayStatus.empty;
  if (summary.day.isAfter(today)) return JournalDayStatus.planned;
  if (summary.pending.isEmpty) return JournalDayStatus.success;
  return summary.day == today
      ? JournalDayStatus.inProgress
      : JournalDayStatus.failure;
}
