import 'package:flutter/material.dart';

import '../../../domain/entities/command.dart';
import '../../../domain/entities/command_event.dart';
import '../../../domain/entities/cycle_note.dart';
import '../../utils/cycle_visual_style.dart';
import '../cycle_note_bottom_sheet.dart';
import '../cycle_note_indicator.dart';

class MonthlyGrid extends StatelessWidget {
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

  const MonthlyGrid({
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
    final now = DateTime.now().toUtc();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final cycleStart = DateTime.utc(year, month, 1);
        if (!isCycleVisible(
          frequency: Frequency.monthly,
          cycleStartUtc: cycleStart,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final key = '$year-${month.toString().padLeft(2, '0')}';
        final success = hasComplete(grouped[key] ?? const <CommandEvent>[]);
        final isCurrent = key == currentKey;
        final isPast = DateTime.utc(
          year,
          month,
          1,
        ).isBefore(DateTime.utc(now.year, now.month, 1));
        final status = statusForCycle(
          isSuccess: success,
          isCurrent: isCurrent,
          isPast: isPast,
        );
        final canCompletePastCycle = !success && !isCurrent && isPast;
        final canUncompletePastCycle = success && !isCurrent && isPast;
        final style = styleForStatus(status, context);
        final textColor = accessibleForegroundColor(
          backgroundColor: style.backgroundColor,
          context: context,
        );
        final hasNote = notes.containsKey(key);
        final semanticsNote = hasNote ? ', note enregistrée' : '';
        final cycleLabel = '${monthLabel(month)} $year';
        final semanticsAction = (canCompletePastCycle || canUncompletePastCycle)
            ? 'Appuyez pour choisir entre compléter ou ajouter une note.'
            : 'Appuyez pour ajouter ou modifier une note.';

        return Semantics(
          label:
              '$cycleLabel : ${statusSemantics(status)}$semanticsNote. $semanticsAction',
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _onCycleTap(
                context: context,
                cycleKey: key,
                cycleLabel: cycleLabel,
                canCompletePastCycle: canCompletePastCycle,
                canUncompletePastCycle: canUncompletePastCycle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: style.backgroundColor,
                        border: Border.all(
                          color: style.indicatorColor.withValues(alpha: 0.55),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(style.stateIcon, size: 12, color: textColor),
                          const SizedBox(width: 4),
                          Text(
                            month.toString().padLeft(2, '0'),
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
                    top: -2,
                    right: -2,
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
