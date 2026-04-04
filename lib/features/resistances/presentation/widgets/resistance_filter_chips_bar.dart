import 'package:flutter/material.dart';

import '../../domain/usecases/filter_and_sort_resistances_usecase.dart';
import 'resistance_filter_bottom_sheet.dart';

class ResistanceFilterChipsBar extends StatefulWidget {
  final ResistanceFilterSettings current;
  final void Function(Set<String> tags) onTagsChanged;
  final void Function(ResistanceSort sort) onSortChanged;

  const ResistanceFilterChipsBar({
    super.key,
    required this.current,
    required this.onTagsChanged,
    required this.onSortChanged,
  });

  @override
  State<ResistanceFilterChipsBar> createState() =>
      _ResistanceFilterChipsBarState();
}

class _ResistanceFilterChipsBarState extends State<ResistanceFilterChipsBar> {
  bool _expanded = false;

  List<_ActiveChip> _activeChips() {
    final chips = <_ActiveChip>[];

    for (final tag in widget.current.selectedTags) {
      chips.add(
        _ActiveChip(
          label: '#$tag',
          onRemove: () {
            final next = Set<String>.from(widget.current.selectedTags)
              ..remove(tag);
            widget.onTagsChanged(next);
          },
        ),
      );
    }

    if (widget.current.sort != ResistanceSort.alpha) {
      chips.add(
        _ActiveChip(
          label: _sortLabel(widget.current.sort),
          onRemove: () => widget.onSortChanged(ResistanceSort.alpha),
        ),
      );
    }

    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final chips = _activeChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    final visible = _expanded ? chips : chips.take(3).toList();
    final hasMore = chips.length > visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...visible.map(
              (c) => InputChip(
                label: Text(c.label),
                onDeleted: c.onRemove,
                visualDensity: VisualDensity.compact,
              ),
            ),
            if (hasMore)
              ActionChip(
                label: Text(_expanded ? 'Réduire' : '+${chips.length - 3}'),
                onPressed: () => setState(() => _expanded = !_expanded),
                visualDensity: VisualDensity.compact,
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

String _sortLabel(ResistanceSort sort) {
  switch (sort) {
    case ResistanceSort.alpha:
      return 'Manuel';
    case ResistanceSort.streakHigh:
      return 'Série ↓';
    case ResistanceSort.streakLow:
      return 'Série ↑';
  }
}
