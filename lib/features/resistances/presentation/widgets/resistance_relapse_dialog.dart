import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/resistance_relapse.dart';

/// Retourne `null` si annulé, sinon la note éventuelle (peut être vide).
Future<String?> showResistanceRelapseDialog({
  required BuildContext context,
  required String resistanceTitle,
  required int currentStreakDays,
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _ResistanceRelapseDialog(
      resistanceTitle: resistanceTitle,
      currentStreakDays: currentStreakDays,
    ),
  );
}

class _ResistanceRelapseDialog extends StatefulWidget {
  final String resistanceTitle;
  final int currentStreakDays;

  const _ResistanceRelapseDialog({
    required this.resistanceTitle,
    required this.currentStreakDays,
  });

  @override
  State<_ResistanceRelapseDialog> createState() =>
      _ResistanceRelapseDialogState();
}

class _ResistanceRelapseDialogState extends State<_ResistanceRelapseDialog> {
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmer la rechute ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '« ${widget.resistanceTitle} »',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Vous allez remettre à zéro votre série de ${widget.currentStreakDays} jour${widget.currentStreakDays > 1 ? 's' : ''}.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              maxLines: 3,
              maxLength: ResistanceRelapse.maxNoteLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optionnelle)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pop(_noteController.text.trim());
          },
          child: const Text(
            'J’ai craqué',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
