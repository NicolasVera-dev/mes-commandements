import 'cycle_visual_style.dart';

/// Libellé court français pour un [cycleKey] (titre de feuille / dialogue).
String cycleKeyDisplayLabel(String cycleKey) {
  final daily = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(cycleKey);
  if (daily != null) {
    final y = int.parse(daily.group(1)!);
    final m = int.parse(daily.group(2)!);
    final d = int.parse(daily.group(3)!);
    return '$d ${monthLabel(m)} $y';
  }

  final weekly = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
  if (weekly != null) {
    final y = weekly.group(1)!;
    final w = weekly.group(2)!;
    return 'Semaine $w ($y)';
  }

  final monthly = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(cycleKey);
  if (monthly != null) {
    final y = int.parse(monthly.group(1)!);
    final m = int.parse(monthly.group(2)!);
    return '${monthLabel(m)} $y';
  }

  final yearly = RegExp(r'^(\d{4})$').firstMatch(cycleKey);
  if (yearly != null) {
    return 'Année ${yearly.group(1)}';
  }

  return cycleKey;
}
