import 'package:meta/meta.dart';

@immutable
class ResistanceRelapse {
  static const int maxNoteLength = 300;

  final String id;
  final String resistanceId;
  final DateTime relapsedAtUtc;
  final int previousStreakDays;
  final String? note;

  const ResistanceRelapse({
    required this.id,
    required this.resistanceId,
    required this.relapsedAtUtc,
    required this.previousStreakDays,
    this.note,
  }) : assert(previousStreakDays >= 0);

  factory ResistanceRelapse.fromMap({
    required String id,
    required String resistanceId,
    required Map<String, Object?> map,
  }) {
    final relapsedAtUtc =
        _parseDateTime(map['relapsedAtUtc']) ?? DateTime.utc(1970, 1, 1);
    final rawPrev = map['previousStreakDays'];
    final previousStreakDays = rawPrev is num
        ? rawPrev.toInt()
        : int.tryParse((rawPrev ?? '0').toString()) ?? 0;
    final rawNote = map['note'];
    final note = rawNote == null || rawNote.toString().trim().isEmpty
        ? null
        : rawNote.toString().trim();

    return ResistanceRelapse(
      id: id,
      resistanceId: resistanceId,
      relapsedAtUtc: relapsedAtUtc,
      previousStreakDays: previousStreakDays < 0 ? 0 : previousStreakDays,
      note: note != null && note.length > maxNoteLength
          ? note.substring(0, maxNoteLength)
          : note,
    );
  }

  static DateTime? _parseDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    try {
      final dynamicValue = raw as dynamic;
      final timestampDate = dynamicValue.toDate();
      if (timestampDate is DateTime) return timestampDate.toUtc();
    } catch (_) {}
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toUtc();
  }
}
