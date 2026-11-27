import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../localization/localization.dart';

/// Shared layout for command cycle notes and resistance relapse notes.
class NoteEditorBody extends StatelessWidget {
  const NoteEditorBody({
    super.key,
    required this.controller,
    required this.title,
    required this.hint,
    required this.maxLength,
    required this.saving,
    required this.isDirty,
    required this.onSave,
    this.onDelete,
  });

  final TextEditingController controller;
  final String title;
  final String hint;
  final int maxLength;
  final bool saving;
  final bool isDirty;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final length = controller.text.characters.length;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: !saving,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterText: '$length / $maxLength',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (onDelete != null)
                  TextButton(
                    onPressed: saving ? null : onDelete,
                    child: Text(context.l10n.supprimer),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: !saving && isDirty && length <= maxLength
                      ? onSave
                      : null,
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.l10n.enregistrer),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
