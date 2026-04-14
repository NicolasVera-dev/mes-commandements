import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../../domain/entities/cycle_note.dart';
import '../../utils/cycle_visual_style.dart';
import '../cycle_note_bottom_sheet.dart';
import '../cycle_note_indicator.dart';

class DailyCalendar extends StatelessWidget {
  final DateTime anchorUtc;
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

  const DailyCalendar({
    super.key,
    required this.anchorUtc,
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
    final start = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final end = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    final days = end.difference(start).inDays;

    final now = DateTime.now().toUtc();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = DateTime.utc(anchorUtc.year, anchorUtc.month, index + 1);
        if (!isCycleVisible(
          frequency: Frequency.daily,
          cycleStartUtc: day,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final key =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final events = grouped[key] ?? const <CommandEvent>[];
        final success = hasComplete(events);
        final isCurrent = key == currentKey;
        final isPast = day.isBefore(DateTime.utc(now.year, now.month, now.day));
        final status = statusForCycle(
          isSuccess: success,
          isCurrent: isCurrent,
          isPast: isPast,
        );
        final style = styleForStatus(status, context);
        final canCompletePastCycle = !success && !isCurrent && isPast;
        final canUncompletePastCycle = success && !isCurrent && isPast;
        final hasNote = notes.containsKey(key);
        final semanticsNote = hasNote ? ', note enregistrée' : '';
        final dayLabel = 'le ${day.day} ${monthLabel(day.month)} ${day.year}';
        final semanticsAction = (canCompletePastCycle || canUncompletePastCycle)
            ? 'Appuyez pour choisir entre compléter ou ajouter une note.'
            : 'Appuyez pour ajouter ou modifier une note.';

        return Semantics(
          label:
              'Jour ${day.day} ${monthLabel(day.month)} ${day.year} : ${statusSemantics(status)}$semanticsNote. $semanticsAction',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _onCycleTap(
                context: context,
                cycleKey: key,
                cycleLabel: dayLabel,
                canCompletePastCycle: canCompletePastCycle,
                canUncompletePastCycle: canUncompletePastCycle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: style.backgroundColor,
                        border: Border.all(
                          color: style.indicatorColor.withValues(alpha: 0.6),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: style.indicatorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: CycleNoteIndicator(
                      hasNote: hasNote,
                      onPressed: () => _openNote(context, key),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
