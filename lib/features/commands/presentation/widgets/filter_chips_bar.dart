import 'package:flutter/material.dart';

import '../../domain/entities/command.dart';
import '../../domain/usecases/filter_and_sort_commands_usecase.dart';

import 'filter_bottom_sheet.dart';
import '../../../../app/localization/localization.dart';

class FilterChipsBar extends StatefulWidget {
  final FilterSettings current;
  final void Function(Set<Frequency>? frequencies) onFrequenciesChanged;
  final void Function(Set<CommandStatusFilter> statuses) onStatusesChanged;
  final void Function(Set<String> tags) onTagsChanged;
  final void Function(CommandSort) onSortChanged;

  const FilterChipsBar({
    super.key,
    required this.current,
    required this.onFrequenciesChanged,
    required this.onStatusesChanged,
    required this.onTagsChanged,
    required this.onSortChanged,
  });

  @override
  State<FilterChipsBar> createState() => _FilterChipsBarState();
}

class _FilterChipsBarState extends State<FilterChipsBar> {
  bool _expanded = false;

  List<_ActiveChip> _activeChips() {
    final List<_ActiveChip> chips = [];

    final selectedFrequencies = widget.current.selectedFrequencies;
    if (selectedFrequencies != null) {
      for (final frequency in selectedFrequencies) {
        chips.add(
          _ActiveChip(
            label: _frequencyLabel(frequency, strings: context.l10n),
            onRemove: () {
              final next = Set<Frequency>.from(selectedFrequencies)
                ..remove(frequency);
              widget.onFrequenciesChanged(next.isEmpty ? null : next);
            },
          ),
        );
      }
    }

    final selectedStatuses = widget.current.selectedStatuses;
    if (selectedStatuses.isNotEmpty) {
      for (final status in selectedStatuses) {
        chips.add(
          _ActiveChip(
            label: _statusLabel(status, strings: context.l10n),
            onRemove: () {
              final next = Set<CommandStatusFilter>.from(selectedStatuses)
                ..remove(status);
              widget.onStatusesChanged(next);
            },
          ),
        );
      }
    }

    final selectedTags = widget.current.selectedTags;
    if (selectedTags.isNotEmpty) {
      for (final tag in selectedTags) {
        chips.add(
          _ActiveChip(
            label: '#$tag',
            onRemove: () {
              final next = Set<String>.from(selectedTags)..remove(tag);
              widget.onTagsChanged(next);
            },
          ),
        );
      }
    }

    if (widget.current.sort != CommandSort.alpha) {
      chips.add(
        _ActiveChip(
          label: _sortLabel(widget.current.sort, strings: context.l10n),
          onRemove: () => widget.onSortChanged(CommandSort.alpha),
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _activeChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    final visibleChips = _expanded ? chips : chips.take(3).toList();
    final hasMore = chips.length > visibleChips.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final chip in visibleChips)
              Chip(label: Text(chip.label), onDeleted: chip.onRemove),
            if (hasMore)
              ActionChip(
                label: Text(
                  _expanded ? context.l10n.reduire : context.l10n.voirPlus,
                ),
                onPressed: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _ActiveChip {
  final String label;
  final VoidCallback onRemove;

  _ActiveChip({required this.label, required this.onRemove});
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

String _statusLabel(CommandStatusFilter status, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  switch (status) {
    case CommandStatusFilter.all:
      return l10n.tous;
    case CommandStatusFilter.notStarted:
      return l10n.nonDemarres;
    case CommandStatusFilter.started:
      return l10n.enCours;
    case CommandStatusFilter.completed:
      return l10n.termines;
    case CommandStatusFilter.paused:
      return l10n.enPause;
  }
}

String _sortLabel(CommandSort sort, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  switch (sort) {
    case CommandSort.alpha:
      return l10n.manuel;
    case CommandSort.completedFirst:
      return l10n.terminesDAbord;
    case CommandSort.highestProgressFirst:
      return l10n.progression3;
    case CommandSort.lowestProgressFirst:
      return l10n.progression2;
    case CommandSort.notCompletedFirst:
      return l10n.nonTerminesDAbord;
  }
}
