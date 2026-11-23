import 'package:flutter/material.dart';

import '../../domain/entities/command.dart';
import '../../domain/usecases/filter_and_sort_commands_usecase.dart';
import '../../../../app/localization/localization.dart';

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
      return _FilterBottomSheet(initial: initial, availableTags: availableTags);
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
                context.l10n.filtres,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 18),
              _SectionTitle(context.l10n.frequence),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: Text(context.l10n.toutes),
                    selected: _frequencies == null,
                    onSelected: (_) => setState(() => _frequencies = null),
                  ),
                  ...Frequency.values.map((frequency) {
                    return FilterChip(
                      label: Text(
                        _frequencyLabel(frequency, strings: context.l10n),
                      ),
                      selected:
                          _frequencies != null &&
                          _frequencies!.contains(frequency),
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
              _SectionTitle(context.l10n.statut),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: Text(context.l10n.tous),
                    selected: _statuses.isEmpty,
                    onSelected: (_) =>
                        setState(() => _statuses = <CommandStatusFilter>{}),
                  ),
                  FilterChip(
                    label: Text(context.l10n.nonDemarres),
                    selected: _statuses.contains(
                      CommandStatusFilter.notStarted,
                    ),
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
                    label: Text(context.l10n.enCours),
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
                    label: Text(context.l10n.termines),
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
              _SectionTitle(context.l10n.tags),
              const SizedBox(height: 10),
              if (widget.availableTags.isEmpty)
                Text(
                  context.l10n.aucunTagDisponiblePourLeMoment,
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: widget.availableTags
                      .map((tag) {
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
                      })
                      .toList(growable: false),
                ),
              const SizedBox(height: 18),
              _SectionTitle(context.l10n.tri),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  FilterChip(
                    label: Text(context.l10n.manuel),
                    selected: _sort == CommandSort.alpha,
                    onSelected: (_) =>
                        setState(() => _sort = CommandSort.alpha),
                  ),
                  FilterChip(
                    label: Text(context.l10n.progression2),
                    selected: _sort == CommandSort.lowestProgressFirst,
                    onSelected: (_) =>
                        setState(() => _sort = CommandSort.lowestProgressFirst),
                  ),
                  FilterChip(
                    label: Text(context.l10n.progression3),
                    selected: _sort == CommandSort.highestProgressFirst,
                    onSelected: (_) => setState(
                      () => _sort = CommandSort.highestProgressFirst,
                    ),
                  ),
                  FilterChip(
                    label: Text(context.l10n.terminesDAbord),
                    selected: _sort == CommandSort.completedFirst,
                    onSelected: (_) =>
                        setState(() => _sort = CommandSort.completedFirst),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: Text(context.l10n.reinitialiser),
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
                      child: Text(context.l10n.valider),
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
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
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
