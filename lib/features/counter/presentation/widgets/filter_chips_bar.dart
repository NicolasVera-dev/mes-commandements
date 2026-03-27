import 'package:flutter/material.dart';

import '../../domain/entities/command.dart';
import '../state/command_provider.dart';

import 'filter_bottom_sheet.dart';

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
            label: _frequencyLabel(frequency),
            onRemove: () {
              final next = Set<Frequency>.from(selectedFrequencies)..remove(frequency);
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
            label: _statusLabel(status),
            onRemove: () {
              final next = Set<CommandStatusFilter>.from(selectedStatuses)..remove(status);
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
          label: _sortLabel(widget.current.sort),
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
              Chip(
                label: Text(chip.label),
                onDeleted: chip.onRemove,
              ),
            if (hasMore)
              ActionChip(
                label: Text(_expanded ? 'Réduire' : 'Voir plus'),
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

  _ActiveChip({
    required this.label,
    required this.onRemove,
  });
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

String _statusLabel(CommandStatusFilter status) {
  switch (status) {
    case CommandStatusFilter.all:
      return 'Tous';
    case CommandStatusFilter.notStarted:
      return 'Non démarrés';
    case CommandStatusFilter.started:
      return 'En cours';
    case CommandStatusFilter.completed:
      return 'Terminés';
  }
}

String _sortLabel(CommandSort sort) {
  switch (sort) {
    case CommandSort.alpha:
      return 'Manuel';
    case CommandSort.completedFirst:
      return "Terminés d'abord";
    case CommandSort.highestProgressFirst:
      return 'Progression ↓';
    case CommandSort.lowestProgressFirst:
      return 'Progression ↑';
    case CommandSort.notCompletedFirst:
      return "Non terminés d'abord";
  }
}

