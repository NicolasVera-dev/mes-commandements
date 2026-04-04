import 'package:meta/meta.dart';

@immutable
class CycleNote {
  final String commandId;
  final String cycleKey;
  final String content;
  final DateTime updatedAtUtc;

  const CycleNote({
    required this.commandId,
    required this.cycleKey,
    required this.content,
    required this.updatedAtUtc,
  });

  static const int maxContentLength = 500;

  CycleNote copyWith({
    String? content,
    DateTime? updatedAtUtc,
  }) {
    return CycleNote(
      commandId: commandId,
      cycleKey: cycleKey,
      content: content ?? this.content,
      updatedAtUtc: updatedAtUtc ?? this.updatedAtUtc,
    );
  }
}
