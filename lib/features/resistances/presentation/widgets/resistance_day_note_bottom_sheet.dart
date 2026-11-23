import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/resistance_day_note.dart';
import '../state/resistance_day_note_provider.dart';
import '../utils/resistance_day_keys.dart';
import '../../../../app/localization/localization.dart';

Future<void> showResistanceDayNoteEditorSheet(
  BuildContext context, {
  required String resistanceId,
  required String dayKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => _ResistanceDayNoteEditorBody(
      resistanceId: resistanceId,
      dayKey: dayKey,
    ),
  );
}

class _ResistanceDayNoteEditorBody extends StatefulWidget {
  final String resistanceId;
  final String dayKey;

  const _ResistanceDayNoteEditorBody({
    required this.resistanceId,
    required this.dayKey,
  });

  @override
  State<_ResistanceDayNoteEditorBody> createState() =>
      _ResistanceDayNoteEditorBodyState();
}

class _ResistanceDayNoteEditorBodyState
    extends State<_ResistanceDayNoteEditorBody> {
  late final TextEditingController _controller;
  late String _initialTrimmed;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ResistanceDayNoteProvider>();
    final existing = provider.noteFor(widget.dayKey)?.content ?? '';
    _controller = TextEditingController(text: existing);
    _initialTrimmed = existing.trim();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasExisting => _initialTrimmed.isNotEmpty;

  bool get _isDirty => _controller.text.trim() != _initialTrimmed;

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final provider = context.read<ResistanceDayNoteProvider>();
    try {
      await provider.saveNote(
        resistanceId: widget.resistanceId,
        dayKey: widget.dayKey,
        content: _controller.text,
      );
      if (!mounted) return;
      navigator.pop();
    } on ArgumentError {
      messenger?.showSnackBar(
        SnackBar(content: Text(context.l10n.erreurEnregistrementNote)),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final provider = context.read<ResistanceDayNoteProvider>();
    final navigator = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.supprimerLaNote),
        content: Text(context.l10n.cetteActionEstIrreversible),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(context.l10n.supprimer),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await provider.saveNote(
      resistanceId: widget.resistanceId,
      dayKey: widget.dayKey,
      content: '',
    );
    if (!mounted) return;
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final label = resistanceDayLabelFr(widget.dayKey, strings: context.l10n);
    final provider = context.watch<ResistanceDayNoteProvider>();
    final saving = provider.isSaving;
    final length = _controller.text.characters.length;
    final canSubmit =
        _isDirty && !saving && length <= ResistanceDayNote.maxContentLength;

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.note(label),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(
                  ResistanceDayNote.maxContentLength,
                ),
              ],
              decoration: InputDecoration(
                hintText: context.l10n.ecrivezUneNotePourCetteJournee,
                border: const OutlineInputBorder(),
                counterText: '$length / ${ResistanceDayNote.maxContentLength}',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_hasExisting)
                  TextButton(
                    onPressed: saving ? null : _confirmDelete,
                    child: Text(context.l10n.supprimer),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: saving
                      ? null
                      : canSubmit
                      ? _save
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
