import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/widgets/dismiss_keyboard_on_tap.dart';
import '../../domain/entities/command.dart';
import '../state/command_provider.dart';
import '../utils/command_form_validators.dart';
import '../widgets/accent_color_picker_field.dart';
import '../widgets/emoji_picker_field.dart';
import '../widgets/tag_input_field.dart';
import '../../../auth/presentation/state/auth_provider.dart';
import '../../../auth/presentation/pages/login_page.dart';

class EditCommandPage extends StatefulWidget {
  final String commandId;

  const EditCommandPage({
    super.key,
    required this.commandId,
  });

  @override
  State<EditCommandPage> createState() => _EditCommandPageState();
}

class _EditCommandPageState extends State<EditCommandPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _targetController;
  late final TextEditingController _progressController;

  Frequency _frequency = Frequency.daily;
  String _emoji = Command.defaultEmoji;
  int? _accentColorValue;
  List<String> _tags = <String>[];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _targetController = TextEditingController();
    _progressController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<CommandProvider>();
    final command = provider.getById(widget.commandId);

    if (command == null || _initialized) return;

    _frequency = command.frequency;
    _titleController.text = command.title;
    _descriptionController.text = command.description;
    _targetController.text = command.target.toString();
    _progressController.text = command.progress.toString();
    _emoji = command.emoji;
    _accentColorValue = command.accentColorValue;
    _tags = List<String>.from(command.tags);

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isInitialLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Vérification de la session...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (!auth.isConnected) {
      return const LoginPage();
    }

    final commandProvider = context.watch<CommandProvider>();
    final command = commandProvider.getById(widget.commandId);

    return DismissKeyboardOnTap(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Modifier le commandement',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        body: command == null
            ? Center(
                child: Text(
                  'Commandement introuvable.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : SafeArea(
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                    Text(
                      'Détails',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Essentiel',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      maxLength: Command.maxTitleLength,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Titre',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 2) {
                          return 'Veuillez entrer un titre (min. 2)';
                        }
                        if (v.length > Command.maxTitleLength) {
                          return 'Le titre ne doit pas dépasser ${Command.maxTitleLength} caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<Frequency>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(
                        labelText: 'Fréquence',
                        prefixIcon: Icon(Icons.schedule),
                      ),
                      items: Frequency.values.map((frequency) {
                        return DropdownMenuItem<Frequency>(
                          value: frequency,
                          child: Text(_frequencyLabel(frequency)),
                        );
                      }).toList(growable: false),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _frequency = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Objectif',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: validateRequiredPositiveInt,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _progressController,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Progression',
                        prefixIcon: Icon(Icons.timeline),
                      ),
                      validator: (value) {
                        final p = parseNonNegativeInt(value ?? '');
                        if (p == null) return 'Veuillez entrer un nombre valide';

                        final t = parsePositiveInt(_targetController.text);
                        if (t != null && p > t) {
                          return 'La progression ne peut pas dépasser l’objectif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      minLines: 2,
                      maxLength: Command.maxDescriptionLength,
                      textInputAction: TextInputAction.newline,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Description (optionnelle)',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.notes_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Personnalisation visuelle',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    EmojiPickerField(
                      selectedEmoji: _emoji,
                      onChanged: (emoji) => setState(() => _emoji = emoji),
                    ),
                    AccentColorPickerField(
                      selectedColorValue: _accentColorValue,
                      emojiPreview: _emoji,
                      onChanged: (colorValue) =>
                          setState(() => _accentColorValue = colorValue),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Organisation',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TagInputField(
                      initialTags: _tags,
                      suggestions: commandProvider.availableTags,
                      accentColorValue: _accentColorValue,
                      onChanged: (tags) => setState(() => _tags = tags),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        final isValid =
                            _formKey.currentState?.validate() ?? false;
                        if (!isValid) return;

                        final title = _titleController.text.trim();
                        final description = _descriptionController.text.trim();
                        final target = parsePositiveInt(_targetController.text);
                        final progress =
                            parseNonNegativeInt(_progressController.text);
                        if (title.isEmpty ||
                            target == null ||
                            progress == null) {
                          return;
                        }

                        final clampedProgress =
                            progress > target ? target : progress;

                        commandProvider.updateCommand(
                          command.copyWith(
                            title: title,
                            description: description,
                            target: target,
                            progress: clampedProgress,
                            frequency: _frequency,
                            emoji: _emoji,
                            accentColorValue: _accentColorValue,
                            clearAccentColorValue: _accentColorValue == null,
                            tags: _tags,
                          ),
                        );

                        Navigator.of(context).pop();
                      },
                      child: const Text('Enregistrer'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Annuler'),
                    ),
                  ],
                ),
              ),
            ),
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

