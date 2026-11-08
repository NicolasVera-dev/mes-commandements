import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/entities/command.dart';
import '../../domain/usecases/compute_streak_usecase.dart';

/// Badge pill emoji + libellé pour la série sous le titre.
class CommandStreakBadge extends StatelessWidget {
  const CommandStreakBadge({
    super.key,
    required this.result,
    required this.frequency,
    required this.compact,
  });

  final StreakResult result;
  final Frequency frequency;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (result.badge == StreakBadge.none) {
      return const SizedBox.shrink();
    }

    final semantic = Theme.of(context).extension<AppSemanticColors>();
    final isPositive = !result.badge.isNegative;
    final background = isPositive
        ? (semantic?.successBackground ??
              Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.35))
        : (semantic?.failedBackground ??
              Theme.of(context).colorScheme.errorContainer
                  .withValues(alpha: 0.35));
    final foreground = isPositive
        ? (semantic?.successIndicator ??
              Theme.of(context).colorScheme.onPrimaryContainer)
        : (semantic?.failedIndicator ?? Theme.of(context).colorScheme.error);

    final (emoji, title) = _badgeContent(result.badge);
    final label = result.badge == StreakBadge.recovered
        ? title
        : '$title · ${_countLabel(result, frequency)}';
    final fontSize = compact ? 11.5 : 12.5;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 3 : 4,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: compact ? 13 : 14, height: 1.1),
            ),
            SizedBox(width: compact ? 4 : 6),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(String, String) _badgeContent(StreakBadge badge) {
  return switch (badge) {
    StreakBadge.none => ('', ''),
    StreakBadge.recovered => ('✨', 'Reprise'),
    StreakBadge.goodStart => ('🌱', 'Bon départ'),
    StreakBadge.inRhythm => ('🔥', 'En rythme'),
    StreakBadge.solidStreak => ('💪', 'Série solide'),
    StreakBadge.consistent => ('⭐', 'Belle régularité'),
    StreakBadge.momentum => ('🚀', 'Sur ta lancée'),
    StreakBadge.milestone => ('🏅', 'Cap franchi'),
    StreakBadge.established => ('👑', 'Habitude ancrée'),
    StreakBadge.legendary => ('🏆', 'Série légendaire'),
    StreakBadge.missedOccasion => ('🌥️', 'Faux pas'),
    StreakBadge.setback => ('🟡', 'Ça coince'),
    StreakBadge.findRhythm => ('🟠', 'Ça déraille'),
    StreakBadge.slowingDown => ('🍂', 'Coup dur'),
    StreakBadge.adjustGoal => ('🧭', 'Zone rouge'),
    StreakBadge.smallStep => ('👣', 'Plus d’élan'),
    StreakBadge.freshStart => ('🔄', 'Panne sèche'),
    StreakBadge.rethinkDirection => ('🎯', 'Crash'),
  };
}

String _countLabel(StreakResult result, Frequency frequency) {
  final count = result.count;
  final single = count == 1;
  final negative = result.badge.isNegative;
  final description = switch ((frequency, negative, single)) {
    (Frequency.daily, false, _) => 'jours réussis',
    (Frequency.weekly, false, _) => 'semaines réussies',
    (Frequency.monthly, false, _) => 'mois réussis',
    (Frequency.yearly, false, _) => 'années réussies',
    (Frequency.daily, true, true) => 'jour manqué',
    (Frequency.daily, true, false) => 'jours manqués',
    (Frequency.weekly, true, true) => 'semaine manquée',
    (Frequency.weekly, true, false) => 'semaines manquées',
    (Frequency.monthly, true, true) => 'mois manqué',
    (Frequency.monthly, true, false) => 'mois manqués',
    (Frequency.yearly, true, true) => 'année manquée',
    (Frequency.yearly, true, false) => 'années manquées',
  };
  return '$count $description';
}
