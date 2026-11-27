import 'package:flutter/material.dart';

import '../../../../app/widgets/creation_sheet.dart';

import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../domain/entities/journal_day.dart';
import '../../domain/entities/journal_task.dart';
import '../state/journal_provider.dart';

Future<void> showJournalTaskSheet(
  BuildContext context, {
  required JournalDay day,
  JournalTask? task,
}) => showCreationSheet<void>(
  context: context,
  builder: (_) => _TaskEditor(day: day, task: task),
);

class _TaskEditor extends StatefulWidget {
  final JournalDay day;
  final JournalTask? task;
  const _TaskEditor({required this.day, this.task});
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _title;
  late JournalDay _day;
  late bool _priority;
  late bool _carryForward;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.task?.title);
    _day = widget.day;
    _priority = widget.task?.priority ?? false;
    _carryForward = widget.task?.carryForward ?? true;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<JournalProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final strings = context.l10n;
    try {
      if (widget.task case final task?) {
        await provider.edit(
          task.id,
          title: _title.text,
          priority: _priority,
          carryForward: _carryForward,
        );
      } else {
        await provider.add(
          title: _title.text,
          day: _day,
          priority: _priority,
          carryForward: _carryForward,
        );
      }
      if (mounted) {
        Navigator.of(context).pop();
        if (widget.task != null)
          messenger.showSnackBar(
            SnackBar(
              content: Text(strings.journalTaskUpdated),
              persist: false,
              duration: const Duration(seconds: 3),
              showCloseIcon: true,
            ),
          );
      }
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
    final dates = MaterialLocalizations.of(context);
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
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.task == null
                      ? strings.journalAddTask
                      : strings.journalEditTask,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  autofocus: false,
                  enabled: !_saving,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: strings.journalTaskTitle,
                    hintText: strings.journalTaskHint,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null ||
                          value.trim().isEmpty ||
                          value.trim().length > 200
                      ? strings.journalTaskRequired
                      : null,
                ),
                if (widget.task == null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      _day == context.watch<JournalProvider>().today
                          ? strings.journalPlannedToday
                          : strings.journalPlannedFor(
                              dates.formatMediumDate(_day.date),
                            ),
                    ),
                    onTap: _saving
                        ? null
                        : () async {
                            final today = context.read<JournalProvider>().today;
                            final date = await showDatePicker(
                              context: context,
                              initialDate:
                                  (_day.isBefore(today) ? today : _day).date,
                              firstDate: today.date,
                              lastDate: today.add(3650).date,
                            );
                            if (date != null && mounted) {
                              setState(() => _day = JournalDay.fromDate(date));
                            }
                          },
                  ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.journalPriority),
                  subtitle: Text(strings.journalPriorityHelp),
                  value: _priority,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _priority = value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(strings.journalReportable),
                  subtitle: Text(strings.journalReportableHelp),
                  value: _carryForward,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _carryForward = value),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(strings.journalSave),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
