import 'package:flutter/material.dart';

import '../../domain/usecases/filter_and_sort_resistances_usecase.dart';
import '../../../../app/localization/localization.dart';

class ResistanceFilterSettings {
  final Set<String> selectedTags;
  final ResistanceSort sort;

  const ResistanceFilterSettings({
    required this.selectedTags,
    required this.sort,
  });
}

Future<ResistanceFilterSettings?> showResistanceFilterBottomSheet({
  required BuildContext context,
  required ResistanceFilterSettings initial,
  required List<String> availableTags,
}) {
  return showModalBottomSheet<ResistanceFilterSettings>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _ResistanceFilterBottomSheet(
      initial: initial,
      availableTags: availableTags,
    ),
  );
}

class _ResistanceFilterBottomSheet extends StatefulWidget {
  final ResistanceFilterSettings initial;
  final List<String> availableTags;

  const _ResistanceFilterBottomSheet({
    required this.initial,
    required this.availableTags,
  });

  @override
  State<_ResistanceFilterBottomSheet> createState() =>
      _ResistanceFilterBottomSheetState();
}

class _ResistanceFilterBottomSheetState
    extends State<_ResistanceFilterBottomSheet> {
  late Set<String> _tags;
  late ResistanceSort _sort;

  @override
  void initState() {
    super.initState();
    _tags = Set<String>.from(widget.initial.selectedTags);
    _sort = widget.initial.sort;
  }

  void _reset() {
    setState(() {
      _tags = <String>{};
      _sort = ResistanceSort.alpha;
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
        child: ListView(
          children: [
            const SizedBox(height: 6),
            Text(
              context.l10n.filtres,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.tags,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            if (widget.availableTags.isEmpty)
              Text(
                context.l10n.aucunTagPourLeMoment,
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
            Text(
              context.l10n.tri,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                FilterChip(
                  label: Text(context.l10n.manuel),
                  selected: _sort == ResistanceSort.alpha,
                  onSelected: (_) =>
                      setState(() => _sort = ResistanceSort.alpha),
                ),
                FilterChip(
                  label: Text(context.l10n.serie2),
                  selected: _sort == ResistanceSort.streakHigh,
                  onSelected: (_) =>
                      setState(() => _sort = ResistanceSort.streakHigh),
                ),
                FilterChip(
                  label: Text(context.l10n.serie),
                  selected: _sort == ResistanceSort.streakLow,
                  onSelected: (_) =>
                      setState(() => _sort = ResistanceSort.streakLow),
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
                      Navigator.of(context).pop(
                        ResistanceFilterSettings(
                          selectedTags: _tags,
                          sort: _sort,
                        ),
                      );
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
    );
  }
}
