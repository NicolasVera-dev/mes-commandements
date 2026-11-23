import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/entities/command.dart';
import '../../domain/usecases/compute_streak_usecase.dart';
import '../../../../app/localization/localization.dart';

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

    final (emoji, title) = _badgeContent(result.badge, strings: context.l10n);
    final label = result.badge == StreakBadge.recovered
        ? title
        : '$title · ${_countLabel(result, frequency, strings: context.l10n)}';
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

(String, String) _badgeContent(StreakBadge badge, {AppLocalizations? strings}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  return switch (badge) {
    StreakBadge.none => ('', ''),
    StreakBadge.recovered => ('✨', l10n.reprise),
    StreakBadge.goodStart => ('🌱', l10n.bonDepart),
    StreakBadge.inRhythm => ('🔥', l10n.enRythme),
    StreakBadge.solidStreak => ('💪', l10n.serieSolide),
    StreakBadge.consistent => ('⭐', l10n.belleRegularite),
    StreakBadge.momentum => ('🚀', l10n.surTaLancee),
    StreakBadge.milestone => ('🏅', l10n.capFranchi),
    StreakBadge.established => ('👑', l10n.habitudeAncree),
    StreakBadge.legendary => ('🏆', l10n.serieLegendaire),
    StreakBadge.missedOccasion => ('🌥️', l10n.fauxPas),
    StreakBadge.setback => ('🟡', l10n.caCoince),
    StreakBadge.findRhythm => ('🟠', l10n.caDeraille),
    StreakBadge.slowingDown => ('🍂', l10n.coupDur),
    StreakBadge.adjustGoal => ('🧭', l10n.zoneRouge),
    StreakBadge.smallStep => ('👣', l10n.plusDelan),
    StreakBadge.freshStart => ('🔄', l10n.panneSeche),
    StreakBadge.rethinkDirection => ('🎯', l10n.crash),
  };
}

String _countLabel(
  StreakResult result,
  Frequency frequency, {
  AppLocalizations? strings,
}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  final count = result.count;
  final single = count == 1;
  final negative = result.badge.isNegative;
  final description = switch ((frequency, negative, single)) {
    (Frequency.daily, false, _) => l10n.joursReussis,
    (Frequency.weekly, false, _) => l10n.semainesReussies,
    (Frequency.monthly, false, _) => l10n.moisReussis,
    (Frequency.yearly, false, _) => l10n.anneesReussies,
    (Frequency.daily, true, true) => l10n.jourManque,
    (Frequency.daily, true, false) => l10n.joursManques,
    (Frequency.weekly, true, true) => l10n.semaineManquee,
    (Frequency.weekly, true, false) => l10n.semainesManquees,
    (Frequency.monthly, true, true) => l10n.moisManque,
    (Frequency.monthly, true, false) => l10n.moisManques,
    (Frequency.yearly, true, true) => l10n.anneeManquee,
    (Frequency.yearly, true, false) => l10n.anneesManquees,
  };
  return '$count $description';
}
