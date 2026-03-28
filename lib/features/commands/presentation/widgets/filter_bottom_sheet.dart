import 'package:flutter/material.dart';

import '../../domain/entities/command.dart';
import '../../domain/usecases/filter_and_sort_commands_usecase.dart';

class FilterSettings {
  /// null => "Toutes" (no frequency filtering).
  final Set<Frequency>? selectedFrequencies;
  /// empty => "Tous" (no status filtering)
  final Set<CommandStatusFilter> selectedStatuses;
  final Set<String> selectedTags;
  final CommandSort sort;

  const FilterSettings({
    required this.selectedFrequencies,
    required this.selectedStatuses,
    required this.selectedTags,
    required this.sort,
  });
}

Future<FilterSettings?> showFilterBottomSheet({
  required BuildContext context,
  required FilterSettings initial,
  required List<String> availableTags,
}) {
  return showModalBottomSheet<FilterSettings>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return _FilterBottomSheet(
        initial: initial,
        availableTags: availableTags,
      );
    },
  );
}

class _FilterBottomSheet extends StatefulWidget {
  final FilterSettings initial;
  final List<String> availableTags;

  const _FilterBottomSheet({
    required this.initial,
    required this.availableTags,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<Frequency>? _frequencies;
  late Set<CommandStatusFilter> _statuses;
  late Set<String> _tags;
  late CommandSort _sort;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _frequencies = widget.initial.selectedFrequencies;
    _statuses = widget.initial.selectedStatuses;
    _tags = Set<String>.from(widget.initial.selectedTags);
    _sort = widget.initial.sort;
  }

  void _reset() {
    setState(() {
      _frequencies = null;
      _statuses = <CommandStatusFilter>{};
      _tags = <String>{};
      _sort = CommandSort.alpha;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          viewPadding.bottom > 0 ? viewPadding.bottom : 16,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 6),
              Text(
                'Filtres',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              _SectionTitle('Fréquence'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Toutes'),
                    selected: _frequencies == null,
                    onSelected: (_) => setState(() => _frequencies = null),
                  ),
                  ...Frequency.values.map((frequency) {
                    return FilterChip(
                      label: Text(_frequencyLabel(frequency)),
                      selected: _frequencies != null && _frequencies!.contains(frequency),
                      onSelected: (_) => setState(() {
                        if (_frequencies == null) {
                          _frequencies = <Frequency>{frequency};
                          return;
                        }

                        final next = Set<Frequency>.from(_frequencies!);
                        if (next.contains(frequency)) {
                          next.remove(frequency);
                        } else {
                          next.add(frequency);
                        }

                        // if empty => "Toutes"
                        _frequencies = next.isEmpty ? null : next;
                      }),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle('Statut'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Tous'),
                    selected: _statuses.isEmpty,
                    onSelected: (_) => setState(() => _statuses = <CommandStatusFilter>{}),
                  ),
                  FilterChip(
                    label: const Text('Non démarrés'),
                    selected: _statuses.contains(CommandStatusFilter.notStarted),
                    onSelected: (_) => setState(() {
                      final next = Set<CommandStatusFilter>.from(_statuses);
                      if (next.contains(CommandStatusFilter.notStarted)) {
                        next.remove(CommandStatusFilter.notStarted);
                      } else {
                        next.add(CommandStatusFilter.notStarted);
                      }
                      _statuses = next;
                    }),
                  ),
                  FilterChip(
                    label: const Text('En cours'),
                    selected: _statuses.contains(CommandStatusFilter.started),
                    onSelected: (_) => setState(() {
                      final next = Set<CommandStatusFilter>.from(_statuses);
                      if (next.contains(CommandStatusFilter.started)) {
                        next.remove(CommandStatusFilter.started);
                      } else {
                        next.add(CommandStatusFilter.started);
                      }
                      _statuses = next;
                    }),
                  ),
                  FilterChip(
                    label: const Text('Terminés'),
                    selected: _statuses.contains(CommandStatusFilter.completed),
                    onSelected: (_) => setState(() {
                      final next = Set<CommandStatusFilter>.from(_statuses);
                      if (next.contains(CommandStatusFilter.completed)) {
                        next.remove(CommandStatusFilter.completed);
                      } else {
                        next.add(CommandStatusFilter.completed);
                      }
                      _statuses = next;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle('Tags'),
              const SizedBox(height: 10),
              if (widget.availableTags.isEmpty)
                Text(
                  'Aucun tag disponible pour le moment.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.availableTags.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: _tags.contains(tag),
                      onSelected: (_) => setState(() {
                        if (_tags.contains(tag)) {
                          _tags.remove(tag);
                        } else {
                          _tags.add(tag);
                        }
                      }),
                    );
                  }).toList(growable: false),
                ),
              const SizedBox(height: 18),
              _SectionTitle('Tri'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: const Text('Manuel'),
                    selected: _sort == CommandSort.alpha,
                    onSelected: (_) =>
                        setState(() => _sort = CommandSort.alpha),
                  ),
                  FilterChip(
                    label: const Text('Progression ↑'),
                    selected: _sort == CommandSort.lowestProgressFirst,
                    onSelected: (_) => setState(
                      () => _sort = CommandSort.lowestProgressFirst,
                    ),
                  ),
                  FilterChip(
                    label: const Text('Progression ↓'),
                    selected: _sort == CommandSort.highestProgressFirst,
                    onSelected: (_) => setState(
                      () => _sort = CommandSort.highestProgressFirst,
                    ),
                  ),
                  FilterChip(
                    label: const Text("Terminés d'abord"),
                    selected: _sort == CommandSort.completedFirst,
                    onSelected: (_) => setState(
                      () => _sort = CommandSort.completedFirst,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final settings = FilterSettings(
                          selectedFrequencies: _frequencies,
                          selectedStatuses: _statuses,
                          selectedTags: _tags,
                          sort: _sort,
                        );
                        Navigator.of(context).pop(settings);
                      },
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium,
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

