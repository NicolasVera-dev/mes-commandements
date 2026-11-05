import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../../domain/entities/cycle_note.dart';
import '../../utils/cycle_visual_style.dart';
import '../cycle_note_bottom_sheet.dart';
import '../cycle_note_indicator.dart';

class YearlyBar extends StatelessWidget {
  final int year;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;
  final String commandId;
  final Map<String, CycleNote> notes;
  final Future<void> Function({
    required String cycleKey,
    required String cycleLabel,
  })?
  onCompletePastCycle;
  final Future<void> Function({
    required String cycleKey,
    required String cycleLabel,
  })?
  onUncompletePastCycle;

  const YearlyBar({
    super.key,
    required this.year,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
    required this.commandId,
    this.notes = const <String, CycleNote>{},
    this.onCompletePastCycle,
    this.onUncompletePastCycle,
  });

  void _openNote(BuildContext context, String cycleKey) {
    showCycleNoteEditorSheet(context, commandId: commandId, cycleKey: cycleKey);
  }

  Future<void> _onCycleTap({
    required BuildContext context,
    required String cycleKey,
    required String cycleLabel,
    required bool canCompletePastCycle,
    required bool canUncompletePastCycle,
  }) async {
    if (!canCompletePastCycle && !canUncompletePastCycle) {
      _openNote(context, cycleKey);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  canCompletePastCycle
                      ? Icons.check_circle_outline_rounded
                      : Icons.remove_circle_outline_rounded,
                ),
                title: Text(
                  canCompletePastCycle
                      ? 'Marquer comme complété'
                      : 'Retirer la complétion',
                ),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  if (canCompletePastCycle) {
                    await onCompletePastCycle?.call(
                      cycleKey: cycleKey,
                      cycleLabel: cycleLabel,
                    );
                  } else {
                    await onUncompletePastCycle?.call(
                      cycleKey: cycleKey,
                      cycleLabel: cycleLabel,
                    );
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: const Text('Ajouter/modifier une note'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openNote(context, cycleKey);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isCycleVisible(
      frequency: Frequency.yearly,
      cycleStartUtc: DateTime.utc(year, 1, 1),
      createdAtUtc: createdAtUtc,
    )) {
      return const SizedBox.shrink();
    }
    final key = '$year';
    final success = hasComplete(grouped[key] ?? const <CommandEvent>[]);
    final nowYear = DateTime.now().toUtc().year;
    final status = statusForCycle(
      isSuccess: success,
      isCurrent: key == currentKey,
      isPast: year < nowYear,
    );
    final canCompletePastCycle =
        !success && key != currentKey && year < nowYear;
    final canUncompletePastCycle =
        success && key != currentKey && year < nowYear;
    final style = styleForStatus(status, context);
    final textColor = accessibleForegroundColor(
      backgroundColor: style.backgroundColor,
      context: context,
    );
    final hasNote = notes.containsKey(key);
    final semanticsNote = hasNote ? ', note enregistrée' : '';
    final semanticsAction = (canCompletePastCycle || canUncompletePastCycle)
        ? 'Appuyez pour choisir entre compléter ou ajouter une note.'
        : 'Appuyez pour ajouter ou modifier une note.';

    return Semantics(
      label:
          'Année $year : ${statusSemantics(status)}$semanticsNote. $semanticsAction',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _onCycleTap(
            context: context,
            cycleKey: key,
            cycleLabel: 'l’année $year',
            canCompletePastCycle: canCompletePastCycle,
            canUncompletePastCycle: canUncompletePastCycle,
          ),
          child: SizedBox(
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Center(
                  child: Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: style.backgroundColor,
                      border: Border.all(
                        color: style.indicatorColor.withValues(alpha: 0.55),
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: style.indicatorColor,
                        ),
                        const SizedBox(width: 4),
                        Icon(style.stateIcon, size: 12, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          '$year',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 8,
                  child: CycleNoteIndicator(
                    hasNote: hasNote,
                    onPressed: () => _openNote(context, key),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
