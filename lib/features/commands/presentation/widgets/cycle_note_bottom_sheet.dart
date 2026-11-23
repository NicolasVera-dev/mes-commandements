import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/cycle_note.dart';
import '../state/cycle_note_provider.dart';
import '../utils/cycle_key_display_label.dart';
import '../../../../app/localization/localization.dart';

Future<void> showCycleNoteEditorSheet(
  BuildContext context, {
  required String commandId,
  required String cycleKey,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) =>
        _CycleNoteEditorBody(commandId: commandId, cycleKey: cycleKey),
  );
}

class _CycleNoteEditorBody extends StatefulWidget {
  final String commandId;
  final String cycleKey;

  const _CycleNoteEditorBody({required this.commandId, required this.cycleKey});

  @override
  State<_CycleNoteEditorBody> createState() => _CycleNoteEditorBodyState();
}

class _CycleNoteEditorBodyState extends State<_CycleNoteEditorBody> {
  late final TextEditingController _controller;
  late String _initialTrimmed;

  @override
  void initState() {
    super.initState();
    final provider = context.read<CycleNoteProvider>();
    final existing = provider.noteFor(widget.cycleKey)?.content ?? '';
    _controller = TextEditingController(text: existing);
    _initialTrimmed = existing.trim();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasExistingNote => _initialTrimmed.isNotEmpty;

  bool get _isDirty => _controller.text.trim() != _initialTrimmed;

  Future<void> _save(BuildContext context) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final provider = context.read<CycleNoteProvider>();
    try {
      await provider.saveNote(
        commandId: widget.commandId,
        cycleKey: widget.cycleKey,
        content: _controller.text,
      );
      if (!mounted) return;
      navigator.pop();
    } on ArgumentError {
      messenger?.showSnackBar(
        SnackBar(content: Text(context.l10n.erreurEnregistrementNote)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? context.l10n.notePermissionSave
          : (e.message?.isNotEmpty == true ? e.message! : e.code);
      messenger?.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _confirmDelete() async {
    final provider = context.read<CycleNoteProvider>();
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

    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await provider.saveNote(
        commandId: widget.commandId,
        cycleKey: widget.cycleKey,
        content: '',
      );
      if (!mounted) return;
      navigator.pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'permission-denied'
          ? context.l10n.notePermissionDelete
          : (e.message?.isNotEmpty == true ? e.message! : e.code);
      messenger?.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = cycleKeyDisplayLabel(widget.cycleKey, strings: context.l10n);
    final provider = context.watch<CycleNoteProvider>();
    final saving = provider.isSaving;
    final length = _controller.text.characters.length;
    final canSubmit =
        _isDirty && !saving && length <= CycleNote.maxContentLength;

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
                LengthLimitingTextInputFormatter(CycleNote.maxContentLength),
              ],
              decoration: InputDecoration(
                hintText: context.l10n.ecrivezUneNotePourCeCycle,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
                counterText: '$length / ${CycleNote.maxContentLength}',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_hasExistingNote)
                  TextButton(
                    onPressed: saving ? null : _confirmDelete,
                    child: Text(context.l10n.supprimer),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: saving
                      ? null
                      : canSubmit
                      ? () => _save(context)
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
