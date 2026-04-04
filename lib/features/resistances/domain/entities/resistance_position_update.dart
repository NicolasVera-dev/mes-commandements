import 'package:meta/meta.dart';

@immutable
class ResistancePositionUpdate {
  final String resistanceId;
  final int position;

  const ResistancePositionUpdate({
    required this.resistanceId,
    required this.position,
  });
}
