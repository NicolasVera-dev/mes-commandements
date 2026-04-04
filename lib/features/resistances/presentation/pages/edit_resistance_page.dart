import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/dismiss_keyboard_on_tap.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../commands/presentation/widgets/accent_color_picker_field.dart';
import '../../../commands/presentation/widgets/emoji_picker_field.dart';
import '../../../commands/presentation/widgets/tag_input_field.dart';
import '../../domain/entities/resistance.dart';
import '../state/resistance_provider.dart';

class EditResistancePage extends StatefulWidget {
  final String resistanceId;

  const EditResistancePage({
    super.key,
    required this.resistanceId,
  });

  @override
  State<EditResistancePage> createState() => _EditResistancePageState();
}

class _EditResistancePageState extends State<EditResistancePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  String _emoji = Resistance.defaultEmoji;
  int? _accentColorValue;
  List<String> _tags = <String>[];
  bool _initialized = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = context.read<ResistanceProvider>().getById(widget.resistanceId);
    if (r == null || _initialized) return;
    _titleController.text = r.title;
    _descriptionController.text = r.description;
    _emoji = r.emoji;
    _accentColorValue = r.accentColorValue;
    _tags = List<String>.from(r.tags);
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isInitialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!auth.isConnected) {
      return const LoginPage();
    }

    final provider = context.watch<ResistanceProvider>();
    final resistance = provider.getById(widget.resistanceId);

    return DismissKeyboardOnTap(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Modifier la résistance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: resistance == null
            ? Center(
                child: Text(
                  'Résistance introuvable.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: Resistance.maxTitleLength,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) {
                            return 'Le titre est obligatoire';
                          }
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
                        maxLines: 4,
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
                        onChanged: (c) =>
                            setState(() => _accentColorValue = c),
                      ),
                      const SizedBox(height: 12),
                      TagInputField(
                        initialTags: _tags,
                        suggestions: provider.availableTags,
                        accentColorValue: _accentColorValue,
                        onChanged: (t) => setState(() => _tags = t),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          if (!(_formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          final updated = resistance.copyWith(
                            title: _titleController.text.trim(),
                            description:
                                _descriptionController.text.trim(),
                            emoji: _emoji,
                            accentColorValue: _accentColorValue,
                            clearAccentColorValue:
                                _accentColorValue == null,
                            tags: _tags,
                          );
                          provider.updateResistance(updated);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Enregistrer'),
                      ),
                    ],
                  ),
                ),
              ),
        ),
    );
  }
}
