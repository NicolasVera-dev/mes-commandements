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
    final isPositive = result.badge == StreakBadge.success1 ||
        result.badge == StreakBadge.success2 ||
        result.badge == StreakBadge.success3 ||
        result.badge == StreakBadge.success4 ||
        result.badge == StreakBadge.recoveredToday;
    final background = isPositive
        ? (semantic?.successBackground ??
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35))
        : (semantic?.failedBackground ??
            Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35));
    final foreground = isPositive
        ? (semantic?.successIndicator ??
            Theme.of(context).colorScheme.onPrimaryContainer)
        : (semantic?.failedIndicator ?? Theme.of(context).colorScheme.error);

    final emoji = _emojiFor(result.badge);
    final label = _labelFor(result, frequency);
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
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _emojiFor(StreakBadge badge) {
  switch (badge) {
    case StreakBadge.none:
      return '';
    case StreakBadge.success1:
      return '🔥';
    case StreakBadge.success2:
      return '🚀';
    case StreakBadge.success3:
      return '👑';
    case StreakBadge.success4:
      return '🏆';
    case StreakBadge.failDaily:
    case StreakBadge.failOther:
      return '😕';
    case StreakBadge.recoveredToday:
      return '✨';
  }
}

String _labelFor(StreakResult result, Frequency frequency) {
  final n = result.count;
  switch (result.badge) {
    case StreakBadge.none:
      return '';
    case StreakBadge.recoveredToday:
      return 'Reprise aujourd’hui';
    case StreakBadge.success1:
    case StreakBadge.success2:
    case StreakBadge.success3:
    case StreakBadge.success4:
      return _successLabel(
        frequency: frequency,
        level: result.badge,
        count: n,
      );
    case StreakBadge.failDaily:
    case StreakBadge.failOther:
      return _failLabel(frequency: frequency, count: n);
  }
}

String _successLabel({
  required Frequency frequency,
  required StreakBadge level,
  required int count,
}) {
  final n = count;
  switch (frequency) {
    case Frequency.daily:
      return switch (level) {
        StreakBadge.success1 => '$n jours réussis',
        StreakBadge.success2 => '$n jours au top',
        StreakBadge.success3 => '$n jours incroyables',
        StreakBadge.success4 => '$n jours légendaires',
        _ => '$n jours réussis',
      };
    case Frequency.weekly:
      return switch (level) {
        StreakBadge.success1 => '$n semaines réussies',
        StreakBadge.success2 => '$n semaines au top',
        StreakBadge.success3 => '$n semaines incroyables',
        StreakBadge.success4 => '$n semaines légendaires',
        _ => '$n semaines réussies',
      };
    case Frequency.monthly:
      return switch (level) {
        StreakBadge.success1 => '$n mois réussis',
        StreakBadge.success2 => '$n mois au top',
        StreakBadge.success3 => '$n mois incroyables',
        StreakBadge.success4 => '$n mois légendaires',
        _ => '$n mois réussis',
      };
    case Frequency.yearly:
      return switch (level) {
        StreakBadge.success1 => '$n années réussies',
        StreakBadge.success2 => '$n années au top',
        StreakBadge.success3 => '$n années incroyables',
        StreakBadge.success4 => '$n années légendaires',
        _ => '$n années réussies',
      };
  }
}

String _failLabel({
  required Frequency frequency,
  required int count,
}) {
  final n = count;
  switch (frequency) {
    case Frequency.daily:
      return '$n jours échoués consécutifs';
    case Frequency.weekly:
      return '$n semaines échouées consécutives';
    case Frequency.monthly:
      return '$n mois échoués consécutifs';
    case Frequency.yearly:
      return '$n années échouées consécutives';
  }
}
