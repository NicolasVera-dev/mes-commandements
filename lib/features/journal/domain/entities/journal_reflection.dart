import 'journal_day.dart';

enum JournalMood { difficult, mixed, satisfied }

class JournalReflection {
  final JournalDay day;
  final String note;
  final JournalMood? mood;

  JournalReflection({required this.day, String note = '', this.mood})
    : note = note.trim() {
    if (this.note.length > 4000) throw ArgumentError('Reflection too long');
  }
}
