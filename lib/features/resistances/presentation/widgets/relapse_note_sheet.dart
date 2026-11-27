import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../../../app/widgets/note_editor_body.dart';
import '../../domain/entities/resistance_relapse.dart';
import '../../domain/repositories/resistance_relapse_repository.dart';
import '../../domain/usecases/save_relapse_note_usecase.dart';

Future<void> showRelapseNoteSheet(
  BuildContext context,
  ResistanceRelapse relapse,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _RelapseNoteEditor(relapse: relapse),
);

class _RelapseNoteEditor extends StatefulWidget {
  final ResistanceRelapse relapse;
  const _RelapseNoteEditor({required this.relapse});
  @override
  State<_RelapseNoteEditor> createState() => _RelapseNoteEditorState();
}

class _RelapseNoteEditorState extends State<_RelapseNoteEditor> {
  late final TextEditingController _note;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _note = TextEditingController(text: widget.relapse.note);
    _note.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save({bool remove = false}) async {
    setState(() => _saving = true);
    final strings = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await SaveRelapseNoteUseCase(context.read<ResistanceRelapseRepository>())
          .execute(
            resistanceId: widget.relapse.resistanceId,
            relapseId: widget.relapse.id,
            note: remove ? '' : _note.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(strings.relapseNoteError)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.supprimerLaNote),
        content: Text(context.l10n.cetteActionEstIrreversible),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.supprimer),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _save(remove: true);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final date = MaterialLocalizations.of(context)
        .formatMediumDate(widget.relapse.relapsedAtUtc.toLocal());
    return PopScope(
      canPop: !_saving,
      child: NoteEditorBody(
        controller: _note,
        title: strings.note(date),
        hint: strings.relapseNoteHint,
        maxLength: ResistanceRelapse.maxNoteLength,
        saving: _saving,
        isDirty: _note.text.trim() != (widget.relapse.note ?? '').trim(),
        onSave: () => _save(),
        onDelete: widget.relapse.note?.trim().isNotEmpty == true
            ? _confirmDelete
            : null,
      ),
    );
  }
}
