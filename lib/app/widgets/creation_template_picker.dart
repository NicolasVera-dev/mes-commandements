import 'package:flutter/material.dart';

/// Ligne de chips horizontales scrollables pour appliquer un modèle au formulaire.
///
/// [onChipSelection] reçoit l’index et si la chip est sélectionnée après le tap
/// (`false` = l’utilisateur a retiré la sélection sans modifier le texte).
class SuggestionTemplateChips extends StatelessWidget {
  final List<String> labels;
  final int? selectedIndex;
  final void Function(int index, bool selected) onChipSelection;

  const SuggestionTemplateChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChipSelection,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Suggestions rapides',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suggestions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 2),
                    child: FilterChip(
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          labels[i],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      selected: selectedIndex == i,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor:
                          scheme.primaryContainer.withValues(alpha: 0.65),
                      checkmarkColor: scheme.onPrimaryContainer,
                      onSelected: (selected) => onChipSelection(i, selected),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
