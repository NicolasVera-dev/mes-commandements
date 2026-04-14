import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/services/cycle_key_generator.dart';

enum CycleVisualStatus { success, failed, current, inactive }

CycleVisualStatus statusForCycle({
  required bool isSuccess,
  required bool isCurrent,
  required bool isPast,
  bool isInactive = false,
}) {
  if (isInactive) return CycleVisualStatus.inactive;
  if (isSuccess) return CycleVisualStatus.success;
  if (isCurrent) return CycleVisualStatus.current;
  if (isPast) return CycleVisualStatus.failed;
  return CycleVisualStatus.current;
}

class CycleStyle {
  final Color backgroundColor;
  final Color indicatorColor;
  final IconData stateIcon;

  const CycleStyle({
    required this.backgroundColor,
    required this.indicatorColor,
    required this.stateIcon,
  });
}

CycleStyle styleForStatus(CycleVisualStatus status, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final semanticColors = Theme.of(context).extension<AppSemanticColors>();
  switch (status) {
    case CycleVisualStatus.success:
      return CycleStyle(
        backgroundColor:
            semanticColors?.successBackground ??
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.12),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.successIndicator ?? scheme.primary,
        stateIcon: Icons.check_rounded,
      );
    case CycleVisualStatus.failed:
      return CycleStyle(
        backgroundColor:
            semanticColors?.failedBackground ??
            Color.alphaBlend(
              scheme.error.withValues(alpha: 0.12),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.failedIndicator ?? scheme.error,
        stateIcon: Icons.close_rounded,
      );
    case CycleVisualStatus.current:
      return CycleStyle(
        backgroundColor:
            semanticColors?.currentBackground ??
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.currentIndicator ?? scheme.outline,
        stateIcon: Icons.schedule_rounded,
      );
    case CycleVisualStatus.inactive:
      return CycleStyle(
        backgroundColor: Color.alphaBlend(
          scheme.surfaceContainerLow.withValues(alpha: 0.6),
          scheme.surface,
        ),
        indicatorColor: scheme.outlineVariant,
        stateIcon: Icons.remove_rounded,
      );
  }
}

String statusSemantics(CycleVisualStatus status) {
  switch (status) {
    case CycleVisualStatus.success:
      return 'objectif atteint';
    case CycleVisualStatus.failed:
      return 'objectif non atteint';
    case CycleVisualStatus.current:
      return 'en cours';
    case CycleVisualStatus.inactive:
      return 'jour inactif';
  }
}

Color progressColorForRatio(BuildContext context, double ratio) {
  final semanticColors = Theme.of(context).extension<AppSemanticColors>();
  if (ratio < 0.5) {
    return semanticColors?.progressLow ?? Theme.of(context).colorScheme.error;
  }
  if (ratio < 0.8) {
    return semanticColors?.progressMedium ??
        Theme.of(context).colorScheme.tertiary;
  }
  return semanticColors?.progressHigh ?? Theme.of(context).colorScheme.primary;
}

Color accessibleForegroundColor({
  required Color backgroundColor,
  required BuildContext context,
}) {
  final baseSurface = Theme.of(context).colorScheme.surface;
  final blendedBackground = Color.alphaBlend(backgroundColor, baseSurface);
  final candidates = <Color>[
    Theme.of(context).colorScheme.onSurface,
    Theme.of(context).colorScheme.onSurfaceVariant,
    Theme.of(context).colorScheme.inverseSurface,
  ];

  var best = candidates.first;
  var bestRatio = _contrastRatio(best, blendedBackground);
  for (final candidate in candidates.skip(1)) {
    final ratio = _contrastRatio(candidate, blendedBackground);
    if (ratio > bestRatio) {
      best = candidate;
      bestRatio = ratio;
    }
  }
  return best;
}

double _contrastRatio(Color foreground, Color background) {
  final l1 = _relativeLuminance(foreground);
  final l2 = _relativeLuminance(background);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double channel(double value) {
    final c = value / 255.0;
    return c <= 0.03928
        ? c / 12.92
        : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

bool hasComplete(List<CommandEvent> events) {
  return events.any((e) => e.type == CommandEventType.complete);
}

String frequencyLabel(Frequency frequency) {
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

String monthLabel(int month) {
  const labels = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];
  return labels[month - 1];
}

bool isCycleVisible({
  required Frequency frequency,
  required DateTime cycleStartUtc,
  required DateTime createdAtUtc,
}) {
  final firstVisibleCycleStart = CycleKeyGenerator.cycleStartUtc(
    frequency,
    createdAtUtc.toUtc(),
  );
  return !cycleStartUtc.toUtc().isBefore(firstVisibleCycleStart);
}
