/// Intervalle UTC de suspension, avec une fin exclusive.
class CommandPause {
  const CommandPause({required this.startUtc, this.endUtc});

  final DateTime startUtc;
  final DateTime? endUtc;

  bool contains(DateTime instant) =>
      !instant.isBefore(startUtc) && (endUtc?.isAfter(instant) ?? true);

  Map<String, Object?> toMap() => {
    'startUtc': startUtc.toUtc().toIso8601String(),
    'endUtc': endUtc?.toUtc().toIso8601String(),
  };

  static CommandPause? fromMap(Object? value) {
    if (value is! Map) return null;
    final start = DateTime.tryParse(value['startUtc']?.toString() ?? '');
    final rawEnd = value['endUtc'];
    final end = DateTime.tryParse(rawEnd?.toString() ?? '');
    if (start == null || (rawEnd != null && end == null)) return null;
    if (end != null && !end.isAfter(start)) return null;
    return CommandPause(startUtc: start.toUtc(), endUtc: end?.toUtc());
  }

  @override
  bool operator ==(Object other) =>
      other is CommandPause &&
      startUtc == other.startUtc &&
      endUtc == other.endUtc;

  @override
  int get hashCode => Object.hash(startUtc, endUtc);
}
