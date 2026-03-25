import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';
import '../utils/command_form_validators.dart';

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
  final TextEditingController _targetController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.read<CommandProvider>();

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
                'Créer un commandement',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Ex: Étudier Dart',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.length < 2) return 'Veuillez entrer un titre (min. 2)';
                  return null;
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
                  hintText: 'Ex: 10',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: validateRequiredPositiveInt,
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
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
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
                    );

                    commandProvider.addCommand(command);
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

