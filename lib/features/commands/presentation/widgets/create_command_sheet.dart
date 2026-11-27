import 'package:flutter/material.dart';

import '../../../../app/widgets/creation_sheet.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/creation_template_picker.dart';
import '../../../../app/widgets/dismiss_keyboard_on_tap.dart';
import '../../domain/entities/command.dart';
import '../state/command_provider.dart';
import '../utils/command_form_validators.dart';
import 'accent_color_picker_field.dart';
import 'command_creation_templates.dart';
import 'emoji_picker_field.dart';
import 'tag_input_field.dart';
import '../../../../app/localization/localization.dart';

Future<void> showCreateCommandSheet({
  required BuildContext context,
  required Frequency initialFrequency,
}) {
  return showCreationSheet<void>(
    context: context,
    builder: (context) {
      return _CreateCommandSheet(initialFrequency: initialFrequency);
    },
  );
}

class _CreateCommandSheet extends StatefulWidget {
  final Frequency initialFrequency;

  const _CreateCommandSheet({required this.initialFrequency});

  @override
  State<_CreateCommandSheet> createState() => _CreateCommandSheetState();
}

class _CreateCommandSheetState extends State<_CreateCommandSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late Frequency _frequency;
  String _emoji = Command.defaultEmoji;
  int? _accentColorValue;
  List<String> _tags = <String>[];
  Set<int> _selectedActiveWeekdays = Command.allWeekdays.toSet();
  final TextEditingController _targetController = TextEditingController();

  /// Chip visuellement sélectionnée ; `null` si aucune ou après édition manuelle.
  int? _selectedSuggestionIndex;
  bool _suppressSuggestionClear = false;

  List<String> get _suggestionLabels => kCommandCreationTemplates
      .map((t) => context.l10n.systemMessage(t.title))
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialFrequency;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _onManualEdit() {
    if (_suppressSuggestionClear) return;
    if (_selectedSuggestionIndex != null) {
      setState(() => _selectedSuggestionIndex = null);
    }
  }

  void _applySuggestion(int index) {
    final t = kCommandCreationTemplates[index];
    _suppressSuggestionClear = true;
    _titleController.text = context.l10n.systemMessage(t.title);
    _descriptionController.text = context.l10n.systemMessage(t.description);
    _targetController.text = t.target.toString();
    setState(() {
      _frequency = t.frequency;
      _emoji = t.emoji;
      _selectedSuggestionIndex = index;
    });
    _suppressSuggestionClear = false;
  }

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.read<CommandProvider>();

    return DismissKeyboardOnTap(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 12,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: _CommandFormBody(
            formKey: _formKey,
            titleController: _titleController,
            descriptionController: _descriptionController,
            targetController: _targetController,
            frequency: _frequency,
            onFrequencyChanged: (f) {
              _onManualEdit();
              setState(() => _frequency = f);
            },
            emoji: _emoji,
            onEmojiChanged: (e) {
              _onManualEdit();
              setState(() => _emoji = e);
            },
            accentColorValue: _accentColorValue,
            onAccentChanged: (c) {
              _onManualEdit();
              setState(() => _accentColorValue = c);
            },
            tags: _tags,
            onTagsChanged: (t) {
              _onManualEdit();
              setState(() => _tags = t);
            },
            selectedActiveWeekdays: _selectedActiveWeekdays,
            onActiveWeekdaysChanged: (weekdays) {
              _onManualEdit();
              setState(() => _selectedActiveWeekdays = weekdays);
            },
            availableTags: commandProvider.availableTags,
            suggestionChips: SuggestionTemplateChips(
              labels: _suggestionLabels,
              selectedIndex: _selectedSuggestionIndex,
              onChipSelection: (i, selected) {
                if (selected) {
                  _applySuggestion(i);
                } else {
                  setState(() => _selectedSuggestionIndex = null);
                }
              },
            ),
            onManualTextEdit: _onManualEdit,
            onSubmit: () {
              final isValid = _formKey.currentState?.validate() ?? false;
              if (!isValid) return;

              final target = parsePositiveInt(_targetController.text)!;
              final title = _titleController.text.trim();
              final description = _descriptionController.text.trim();
              final activeWeekdays =
                  _frequency == Frequency.daily &&
                      _selectedActiveWeekdays.length <
                          Command.allWeekdays.length
                  ? (_selectedActiveWeekdays.toList(growable: false)..sort())
                  : const <int>[];

              final command = Command(
                id: 'cmd-${DateTime.now().microsecondsSinceEpoch}',
                title: title,
                description: description,
                target: target,
                progress: 0,
                frequency: _frequency,
                emoji: _emoji,
                accentColorValue: _accentColorValue,
                tags: _tags,
                activeWeekdays: activeWeekdays,
              );

              commandProvider.addCommand(command);
              Navigator.of(context).pop();
            },
            onCancel: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

class _CommandFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController targetController;
  final Frequency frequency;
  final ValueChanged<Frequency> onFrequencyChanged;
  final String emoji;
  final ValueChanged<String> onEmojiChanged;
  final int? accentColorValue;
  final ValueChanged<int?> onAccentChanged;
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;
  final Set<int> selectedActiveWeekdays;
  final ValueChanged<Set<int>> onActiveWeekdaysChanged;
  final List<String> availableTags;
  final Widget suggestionChips;
  final VoidCallback onManualTextEdit;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  const _CommandFormBody({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.targetController,
    required this.frequency,
    required this.onFrequencyChanged,
    required this.emoji,
    required this.onEmojiChanged,
    required this.accentColorValue,
    required this.onAccentChanged,
    required this.tags,
    required this.onTagsChanged,
    required this.selectedActiveWeekdays,
    required this.onActiveWeekdaysChanged,
    required this.availableTags,
    required this.suggestionChips,
    required this.onManualTextEdit,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.creerUnCommandement,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            suggestionChips,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.essentiel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: titleController,
              maxLength: Command.maxTitleLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) => onManualTextEdit(),
              decoration: InputDecoration(
                labelText: context.l10n.titre,
                hintText: context.l10n.exEtudierDart,
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.length < 2) return context.l10n.veuillezEntrerUnTitreMin2;
                if (v.length > Command.maxTitleLength) {
                  return context.l10n.leTitreNeDoitPasDepasserCaracteres(
                    Command.maxTitleLength,
                  );
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frequency>(
              key: ValueKey<Frequency>(frequency),
              initialValue: frequency,
              decoration: InputDecoration(
                labelText: context.l10n.frequence,
                prefixIcon: Icon(Icons.schedule),
              ),
              items: Frequency.values
                  .map((f) {
                    return DropdownMenuItem<Frequency>(
                      value: f,
                      child: Text(_frequencyLabel(f, strings: context.l10n)),
                    );
                  })
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                onFrequencyChanged(value);
              },
            ),
            if (frequency == Frequency.daily) ...[
              const SizedBox(height: 12),
              _DailyActiveWeekdaysField(
                selectedWeekdays: selectedActiveWeekdays,
                onChanged: onActiveWeekdaysChanged,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: targetController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.next,
              onChanged: (_) => onManualTextEdit(),
              decoration: InputDecoration(
                labelText: context.l10n.objectif,
                hintText: context.l10n.ex10,
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (value) =>
                  validateRequiredPositiveInt(value, strings: context.l10n),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              minLines: 2,
              maxLength: Command.maxDescriptionLength,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.newline,
              onChanged: (_) => onManualTextEdit(),
              decoration: InputDecoration(
                labelText: context.l10n.description,
                hintText: context.l10n.descriptionOptionnelle,
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.personnalisationVisuelle,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            EmojiPickerField(selectedEmoji: emoji, onChanged: onEmojiChanged),
            AccentColorPickerField(
              selectedColorValue: accentColorValue,
              emojiPreview: emoji,
              onChanged: onAccentChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.l10n.organisation,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            TagInputField(
              initialTags: tags,
              suggestions: availableTags,
              accentColorValue: accentColorValue,
              onChanged: onTagsChanged,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                child: Text(context.l10n.enregistrer),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(context.l10n.annuler),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

String _frequencyLabel(Frequency frequency, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  switch (frequency) {
    case Frequency.daily:
      return l10n.quotidien;
    case Frequency.weekly:
      return l10n.hebdomadaire;
    case Frequency.monthly:
      return l10n.mensuel;
    case Frequency.yearly:
      return l10n.annuel;
  }
}

class _DailyActiveWeekdaysField extends StatelessWidget {
  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  const _DailyActiveWeekdaysField({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  static const _tooltips = <int, String>{
    DateTime.monday: 'Lundi',
    DateTime.tuesday: 'Mardi',
    DateTime.wednesday: 'Mercredi',
    DateTime.thursday: 'Jeudi',
    DateTime.friday: 'Vendredi',
    DateTime.saturday: 'Samedi',
    DateTime.sunday: 'Dimanche',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.joursActifs,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Command.allWeekdays
              .map((weekday) {
                final selected = selectedWeekdays.contains(weekday);
                return Tooltip(
                  message: context.l10n.systemMessage(_tooltips[weekday]!),
                  child: FilterChip(
                    selected: selected,
                    label: Text(
                      [
                        context.l10n.jourCourtLundi,
                        context.l10n.jourCourtMardi,
                        context.l10n.jourCourtMercredi,
                        context.l10n.jourCourtJeudi,
                        context.l10n.jourCourtVendredi,
                        context.l10n.jourCourtSamedi,
                        context.l10n.jourCourtDimanche,
                      ][weekday - 1],
                    ),
                    onSelected: (isSelected) {
                      final next = Set<int>.from(selectedWeekdays);
                      if (isSelected) {
                        next.add(weekday);
                      } else {
                        next.remove(weekday);
                      }
                      if (next.isEmpty) return;
                      onChanged(next);
                    },
                  ),
                );
              })
              .toList(growable: false),
        ),
      ],
    );
  }
}
