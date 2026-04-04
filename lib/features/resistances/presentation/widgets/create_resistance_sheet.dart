import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/creation_template_picker.dart';
import '../../../commands/presentation/widgets/accent_color_picker_field.dart';
import '../../../commands/presentation/widgets/emoji_picker_field.dart';
import '../../../commands/presentation/widgets/tag_input_field.dart';
import '../../domain/entities/resistance.dart';
import '../state/resistance_provider.dart';
import 'resistance_creation_templates.dart';

Future<void> showCreateResistanceSheet({required BuildContext context}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _CreateResistanceSheet(),
  );
}

class _CreateResistanceSheet extends StatefulWidget {
  const _CreateResistanceSheet();

  @override
  State<_CreateResistanceSheet> createState() => _CreateResistanceSheetState();
}

class _CreateResistanceSheetState extends State<_CreateResistanceSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _emoji = Resistance.defaultEmoji;
  int? _accentColorValue;
  List<String> _tags = <String>[];

  int? _selectedSuggestionIndex;
  bool _suppressSuggestionClear = false;

  static final List<String> _suggestionLabels = kResistanceCreationTemplates
      .map((t) => t.title)
      .toList(growable: false);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onManualEdit() {
    if (_suppressSuggestionClear) return;
    if (_selectedSuggestionIndex != null) {
      setState(() => _selectedSuggestionIndex = null);
    }
  }

  void _applySuggestion(int index) {
    final t = kResistanceCreationTemplates[index];
    _suppressSuggestionClear = true;
    _titleController.text = t.title;
    _descriptionController.text = t.description;
    setState(() {
      _emoji = t.emoji;
      _selectedSuggestionIndex = index;
    });
    _suppressSuggestionClear = false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ResistanceProvider>();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 12,
      ),
      child: SingleChildScrollView(
        child: _ResistanceFormBody(
          formKey: _formKey,
          titleController: _titleController,
          descriptionController: _descriptionController,
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
          availableTags: provider.availableTags,
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
            final ok = _formKey.currentState?.validate() ?? false;
            if (!ok) return;
            final r = Resistance(
              id: 'res-${DateTime.now().microsecondsSinceEpoch}',
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              createdAtUtc: DateTime.now().toUtc(),
              emoji: _emoji,
              accentColorValue: _accentColorValue,
              tags: _tags,
            );
            provider.addResistance(r);
            Navigator.of(context).pop();
          },
          onCancel: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _ResistanceFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
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

  const _ResistanceFormBody({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nouvelle résistance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          suggestionChips,
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onManualTextEdit(),
            decoration: const InputDecoration(
              labelText: 'Titre',
              border: OutlineInputBorder(),
            ),
            maxLength: Resistance.maxTitleLength,
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.isEmpty) return 'Le titre est obligatoire';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionController,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => onManualTextEdit(),
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            maxLength: Resistance.maxDescriptionLength,
          ),
          const SizedBox(height: 12),
          EmojiPickerField(
            selectedEmoji: emoji,
            preset: EmojiPickerPreset.resistanceAddictions,
            onChanged: onEmojiChanged,
          ),
          const SizedBox(height: 12),
          AccentColorPickerField(
            selectedColorValue: accentColorValue,
            emojiPreview: emoji,
            onChanged: onAccentChanged,
          ),
          const SizedBox(height: 12),
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
    );
  }
}
