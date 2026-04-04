/// Clés `yyyy-MM-dd` (UTC) du jour de création au jour courant inclus.
Set<String> resistanceDayKeysUtc({
  required DateTime createdAtUtc,
  required DateTime nowUtc,
}) {
  final keys = <String>{};
  var d = DateTime.utc(createdAtUtc.year, createdAtUtc.month, createdAtUtc.day);
  final end = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  while (!d.isAfter(end)) {
    keys.add(
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    );
    d = d.add(const Duration(days: 1));
  }
  return keys;
}

String resistanceDayKeyUtc(DateTime dayUtc) {
  final d = dayUtc.toUtc();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String resistanceDayLabelFr(String dayKey) {
  final parts = dayKey.split('-');
  if (parts.length != 3) return dayKey;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (y == null || m == null || day == null) return dayKey;
  const months = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return '$day ${months[m - 1]} $y';
}
