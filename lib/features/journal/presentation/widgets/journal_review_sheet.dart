import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../domain/entities/journal_day.dart';
import '../../domain/entities/journal_reflection.dart';
import '../state/journal_provider.dart';
import 'journal_progress_card.dart';

String journalMoodLabel(AppLocalizations strings, JournalMood mood) =>
    switch (mood) {
      JournalMood.difficult => strings.journalMoodDifficult,
      JournalMood.mixed => strings.journalMoodMixed,
      JournalMood.satisfied => strings.journalMoodSatisfied,
    };

Future<void> showJournalReviewSheet(BuildContext context, JournalDay day) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReviewEditor(day: day),
    );

class _ReviewEditor extends StatefulWidget {
  final JournalDay day;
  const _ReviewEditor({required this.day});
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  late final TextEditingController _note;
  JournalMood? _mood;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    final reflection = context.read<JournalProvider>().reflection(widget.day);
    _note = TextEditingController(text: reflection?.note);
    _mood = reflection?.mood;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<JournalProvider>().saveReflection(
        JournalReflection(day: widget.day, note: _note.text, mood: _mood),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.journalReflectionSaved)),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.journalError)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.l10n;
    final provider = context.watch<JournalProvider>();
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                strings.journalBalance,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                MaterialLocalizations.of(context)
                    .formatFullDate(widget.day.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              JournalProgressCard(summary: provider.summary(widget.day)),
              const SizedBox(height: 24),
              Text(
                strings.journalFeeling,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: JournalMood.values
                    .map(
                      (mood) => ChoiceChip(
                        label: Text(journalMoodLabel(strings, mood)),
                        selected: _mood == mood,
                        onSelected: _saving
                            ? null
                            : (selected) => setState(
                                () => _mood = selected ? mood : null,
                              ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _note,
                enabled: !_saving,
                maxLength: 4000,
                minLines: 3,
                maxLines: 7,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: strings.journalReflection,
                  hintText: strings.journalReflectionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              Text(
                strings.journalReflectionHelp,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(strings.journalSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
