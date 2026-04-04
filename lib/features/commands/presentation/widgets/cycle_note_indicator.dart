import 'package:flutter/material.dart';

/// Pastille de note : visible uniquement lorsqu’une note existe pour le cycle.
class CycleNoteIndicator extends StatelessWidget {
  final bool hasNote;
  final VoidCallback onPressed;

  const CycleNoteIndicator({
    super.key,
    required this.hasNote,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasNote) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'Voir la note',
      child: Semantics(
        button: true,
        label: 'Voir la note du cycle',
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          iconSize: 16,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onPressed,
          icon: Icon(
            Icons.sticky_note_2_outlined,
            color: scheme.tertiary,
          ),
        ),
      ),
    );
  }
}
