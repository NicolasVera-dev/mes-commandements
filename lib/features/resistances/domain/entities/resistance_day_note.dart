import 'package:meta/meta.dart';

@immutable
class ResistanceDayNote {
  final String resistanceId;
  final String dayKey;
  final String content;
  final DateTime updatedAtUtc;

  const ResistanceDayNote({
    required this.resistanceId,
    required this.dayKey,
    required this.content,
    required this.updatedAtUtc,
  });

  static const int maxContentLength = 500;

  ResistanceDayNote copyWith({
    String? content,
    DateTime? updatedAtUtc,
  }) {
    return ResistanceDayNote(
      resistanceId: resistanceId,
      dayKey: dayKey,
      content: content ?? this.content,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}
