/// A calendar date, independent of daylight-saving changes and time of day.
class JournalDay implements Comparable<JournalDay> {
  final String key;

  const JournalDay._(this.key);

  factory JournalDay.fromDate(DateTime date) => JournalDay._(
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}',
  );

  factory JournalDay.parse(String key) {
    final date = DateTime.tryParse(key);
    if (date == null || JournalDay.fromDate(date).key != key) {
      throw FormatException('Invalid journal day', key);
    }
    return JournalDay._(key);
  }

  DateTime get date => DateTime.parse(key);
  DateTime get _utcDate => DateTime.utc(date.year, date.month, date.day);
  JournalDay add(int days) =>
      JournalDay.fromDate(_utcDate.add(Duration(days: days)));
  int daysSince(JournalDay other) => _utcDate.difference(other._utcDate).inDays;
  bool isBefore(JournalDay other) => compareTo(other) < 0;
  bool isAfter(JournalDay other) => compareTo(other) > 0;

  @override
  int compareTo(JournalDay other) => key.compareTo(other.key);
  @override
  bool operator ==(Object other) => other is JournalDay && other.key == key;
  @override
  int get hashCode => key.hashCode;
}
