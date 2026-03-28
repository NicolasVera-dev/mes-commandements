import '../entities/command.dart';

class CycleKeyGenerator {
  const CycleKeyGenerator._();

  static String forFrequency({
    required Frequency frequency,
    required DateTime atUtc,
  }) {
    final date = atUtc.toUtc();
    switch (frequency) {
      case Frequency.daily:
        return _formatDate(date);
      case Frequency.weekly:
        final week = _isoWeek(date);
        final weekYear = _isoWeekYear(date);
        return '$weekYear-S${week.toString().padLeft(2, '0')}';
      case Frequency.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case Frequency.yearly:
        return '${date.year}';
    }
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static int _isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final firstThursday = DateTime.utc(thursday.year, 1, 4);
    final firstWeekThursday = firstThursday
        .add(Duration(days: DateTime.thursday - firstThursday.weekday));
    return 1 + (thursday.difference(firstWeekThursday).inDays ~/ 7);
  }

  static int _isoWeekYear(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    return thursday.year;
  }
}
