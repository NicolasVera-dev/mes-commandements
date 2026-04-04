import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../commands/presentation/widgets/accent_color_picker_field.dart';
import '../../../commands/presentation/widgets/emoji_picker_field.dart';
import '../../../commands/presentation/widgets/tag_input_field.dart';
import '../../domain/entities/resistance.dart';
import '../state/resistance_provider.dart';

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
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Nouvelle résistance',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
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
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
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
                selectedEmoji: _emoji,
                preset: EmojiPickerPreset.resistanceAddictions,
                onChanged: (e) => setState(() => _emoji = e),
              ),
              const SizedBox(height: 12),
              AccentColorPickerField(
                selectedColorValue: _accentColorValue,
                emojiPreview: _emoji,
                onChanged: (c) => setState(() => _accentColorValue = c),
              ),
              const SizedBox(height: 12),
              TagInputField(
                initialTags: _tags,
                suggestions: provider.availableTags,
                accentColorValue: _accentColorValue,
                onChanged: (t) => setState(() => _tags = t),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
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
                  child: const Text('Enregistrer'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
