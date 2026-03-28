import '../entities/command.dart';

class CycleKeyGenerator {
  const CycleKeyGenerator._();

  static DateTime cycleStartUtc(Frequency frequency, DateTime atUtc) {
    final utc = atUtc.toUtc();
    switch (frequency) {
      case Frequency.daily:
        return DateTime.utc(utc.year, utc.month, utc.day);
      case Frequency.weekly:
        final deltaFromMonday = utc.weekday - DateTime.monday;
        final monday = utc.subtract(Duration(days: deltaFromMonday));
        return DateTime.utc(monday.year, monday.month, monday.day);
      case Frequency.monthly:
        return DateTime.utc(utc.year, utc.month, 1);
      case Frequency.yearly:
        return DateTime.utc(utc.year, 1, 1);
    }
  }

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
