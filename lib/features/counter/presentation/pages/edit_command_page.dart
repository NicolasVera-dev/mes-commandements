import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';

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
  late final TextEditingController _targetController;
  late final TextEditingController _progressController;

  Frequency _frequency = Frequency.daily;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _targetController = TextEditingController();
    _progressController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    _targetController.text = command.target.toString();
    _progressController.text = command.progress.toString();

    _initialized = true;
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  @override
  Widget build(BuildContext context) {
    final commandProvider = context.watch<CommandProvider>();
    final command = commandProvider.getById(widget.commandId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le commandement'),
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
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Détails',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
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
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _targetController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Objectif',
                        prefixIcon: Icon(Icons.flag),
                      ),
                      validator: (value) {
                        final t = _parseInt(value ?? '');
                        if (t == null) return 'Veuillez entrer un nombre';
                        if (t <= 0) return "L'objectif doit être > 0";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _progressController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Progress',
                        prefixIcon: Icon(Icons.timeline),
                      ),
                      validator: (value) {
                        final p = _parseInt(value ?? '');
                        if (p == null) return 'Veuillez entrer un nombre';
                        if (p < 0) return 'Le progress doit être >= 0';

                        final t = _parseInt(_targetController.text);
                        if (t != null && p > t) {
                          return 'Le progress ne peut pas dépasser l’objectif';
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
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        final isValid = _formKey.currentState?.validate() ??
                            false;
                        if (!isValid) return;

                        final title = _titleController.text.trim();
                        final target = _parseInt(_targetController.text);
                        final progress = _parseInt(_progressController.text);
                        if (title.isEmpty || target == null || progress == null) {
                          return;
                        }

                        final clampedProgress =
                            progress > target ? target : progress;

                        commandProvider.updateCommand(
                          command.copyWith(
                            title: title,
                            target: target,
                            progress: clampedProgress,
                            frequency: _frequency,
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

