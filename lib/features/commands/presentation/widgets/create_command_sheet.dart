import 'package:flutter/material.dart';
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

Future<void> showCreateCommandSheet({
  required BuildContext context,
  required Frequency initialFrequency,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _CreateCommandSheet(
        initialFrequency: initialFrequency,
      );
    },
  );
}

class _CreateCommandSheet extends StatefulWidget {
  final Frequency initialFrequency;

  const _CreateCommandSheet({
    required this.initialFrequency,
  });

  @override
  State<_CreateCommandSheet> createState() =>
      _CreateCommandSheetState();
}

class _CreateCommandSheetState extends State<_CreateCommandSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late Frequency _frequency;
  String _emoji = Command.defaultEmoji;
  int? _accentColorValue;
  List<String> _tags = <String>[];
  final TextEditingController _targetController = TextEditingController();

  /// Chip visuellement sélectionnée ; `null` si aucune ou après édition manuelle.
  int? _selectedSuggestionIndex;
  bool _suppressSuggestionClear = false;

  static final List<String> _suggestionLabels = kCommandCreationTemplates
      .map((t) => t.title)
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
    _titleController.text = t.title;
    _descriptionController.text = t.description;
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
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
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
              'Créer un commandement',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            suggestionChips,
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Essentiel',
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
              decoration: const InputDecoration(
                labelText: 'Titre',
                hintText: 'Ex: Étudier Dart',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.length < 2) return 'Veuillez entrer un titre (min. 2)';
                if (v.length > Command.maxTitleLength) {
                  return 'Le titre ne doit pas dépasser ${Command.maxTitleLength} caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Frequency>(
              key: ValueKey<Frequency>(frequency),
              initialValue: frequency,
              decoration: const InputDecoration(
                labelText: 'Fréquence',
                prefixIcon: Icon(Icons.schedule),
              ),
              items: Frequency.values.map((f) {
                return DropdownMenuItem<Frequency>(
                  value: f,
                  child: Text(_frequencyLabel(f)),
                );
              }).toList(growable: false),
              onChanged: (value) {
                if (value == null) return;
                onFrequencyChanged(value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: targetController,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              textInputAction: TextInputAction.next,
              onChanged: (_) => onManualTextEdit(),
              decoration: const InputDecoration(
                labelText: 'Objectif',
                hintText: 'Ex: 10',
                prefixIcon: Icon(Icons.flag),
              ),
              validator: validateRequiredPositiveInt,
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
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description (optionnelle)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personnalisation visuelle',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(height: 8),
            EmojiPickerField(
              selectedEmoji: emoji,
              onChanged: onEmojiChanged,
            ),
            AccentColorPickerField(
              selectedColorValue: accentColorValue,
              emojiPreview: emoji,
              onChanged: onAccentChanged,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Organisation',
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
                child: const Text('Enregistrer'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onCancel,
                child: const Text('Annuler'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

String _frequencyLabel(Frequency frequency) {
  switch (frequency) {
    case Frequency.daily:
      return 'Quotidien';
    case Frequency.weekly:
      return 'Hebdomadaire';
    case Frequency.monthly:
      return 'Mensuel';
    case Frequency.yearly:
      return 'Annuel';
  }
}
