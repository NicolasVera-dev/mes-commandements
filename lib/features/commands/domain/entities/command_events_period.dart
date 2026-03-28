class CommandEventsPeriod {
  final DateTime startUtc;
  final DateTime endUtc;

  const CommandEventsPeriod({
    required this.startUtc,
    required this.endUtc,
  });

  factory CommandEventsPeriod.currentMonth(DateTime nowUtc) {
    final now = nowUtc.toUtc();
    final start = DateTime.utc(now.year, now.month, 1);
    final end = now.month == 12
        ? DateTime.utc(now.year + 1, 1, 1)
        : DateTime.utc(now.year, now.month + 1, 1);
    return CommandEventsPeriod(startUtc: start, endUtc: end);
  }
}
