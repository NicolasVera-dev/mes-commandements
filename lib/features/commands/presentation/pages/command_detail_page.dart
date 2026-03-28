import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app/app_theme.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/entities/command_events_period.dart';
import '../../domain/repositories/command_event_repository.dart';
import '../../domain/services/cycle_key_generator.dart';
import '../../domain/usecases/build_cycle_summary_usecase.dart';
import '../state/command_provider.dart';
import '../widgets/dynamic_progress_bar.dart';

class CommandDetailPage extends StatefulWidget {
  final String commandId;

  const CommandDetailPage({
    super.key,
    required this.commandId,
  });

  @override
  State<CommandDetailPage> createState() => _CommandDetailPageState();
}

class _CommandDetailPageState extends State<CommandDetailPage> {
  late DateTime _anchorUtc;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc();
    _anchorUtc = DateTime.utc(now.year, now.month, 1);
  }

  void _goPrevious(Frequency frequency) {
    setState(() {
      if (frequency == Frequency.monthly || frequency == Frequency.yearly) {
        _anchorUtc = DateTime.utc(_anchorUtc.year - 1, 1, 1);
      } else {
        final y = _anchorUtc.month == 1 ? _anchorUtc.year - 1 : _anchorUtc.year;
        final m = _anchorUtc.month == 1 ? 12 : _anchorUtc.month - 1;
        _anchorUtc = DateTime.utc(y, m, 1);
      }
    });
  }

  void _goNext(Frequency frequency) {
    setState(() {
      if (frequency == Frequency.monthly || frequency == Frequency.yearly) {
        _anchorUtc = DateTime.utc(_anchorUtc.year + 1, 1, 1);
      } else {
        final y = _anchorUtc.month == 12 ? _anchorUtc.year + 1 : _anchorUtc.year;
        final m = _anchorUtc.month == 12 ? 1 : _anchorUtc.month + 1;
        _anchorUtc = DateTime.utc(y, m, 1);
      }
    });
  }

  CommandEventsPeriod _periodFor(Frequency frequency) {
    if (frequency == Frequency.monthly || frequency == Frequency.yearly) {
      return CommandEventsPeriod(
        startUtc: DateTime.utc(_anchorUtc.year, 1, 1),
        endUtc: DateTime.utc(_anchorUtc.year + 1, 1, 1),
      );
    }
    return CommandEventsPeriod(
      startUtc: DateTime.utc(_anchorUtc.year, _anchorUtc.month, 1),
      endUtc: _anchorUtc.month == 12
          ? DateTime.utc(_anchorUtc.year + 1, 1, 1)
          : DateTime.utc(_anchorUtc.year, _anchorUtc.month + 1, 1),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommandProvider>();
    final command = provider.getById(widget.commandId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du commandement'),
      ),
      body: command == null
          ? Center(
              child: Text(
                'Commandement introuvable.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : _DetailContent(
              command: command,
              period: _periodFor(command.frequency),
              anchorUtc: _anchorUtc,
              onPrevious: () => _goPrevious(command.frequency),
              onNext: () => _goNext(command.frequency),
            ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final Command command;
  final CommandEventsPeriod period;
  final DateTime anchorUtc;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DetailContent({
    required this.command,
    required this.period,
    required this.anchorUtc,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final eventRepository = context.read<CommandEventRepository>();
    final nextResetText = _nextResetText(command.frequency, DateTime.now().toUtc());
    final periodLabel = (command.frequency == Frequency.monthly || command.frequency == Frequency.yearly)
        ? '${anchorUtc.year}'
        : '${_monthLabel(anchorUtc.month)} ${anchorUtc.year}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Hero(
                      tag: 'command-emoji-${command.id}',
                      child: Material(
                        color: Colors.transparent,
                        child: Text(command.emoji, style: const TextStyle(fontSize: 34)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(command.title, style: Theme.of(context).textTheme.titleLarge),
                          Text(
                            '${_frequencyLabel(command.frequency)} · objectif ${command.target}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DynamicProgressBar(
                  progress: command.progress,
                  target: command.target,
                  accentTintColor: command.accentColorValue == null
                      ? null
                      : Color(command.accentColorValue!),
                ),
                const SizedBox(height: 8),
                Text(nextResetText, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left_rounded),
              tooltip: 'Période précédente',
            ),
            Expanded(
              child: Text(
                periodLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Période suivante',
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<DateTime?>(
          future: command.createdAt == null
              ? eventRepository.firstEventAtUtc(command.id)
              : Future<DateTime?>.value(command.createdAt!.toUtc()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HistorySkeleton();
            }
            if (snapshot.hasError) {
              return Text(
                'Impossible de charger l’historique.',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            final effectiveCreatedAtUtc = snapshot.data?.toUtc();
            if (effectiveCreatedAtUtc == null) {
              return Text(
                'Aucun historique pour ce commandement pour le moment. Continuez, chaque action compte !',
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            return StreamBuilder<List<CommandEvent>>(
              stream: eventRepository.watchEvents(command.id, period: period),
              builder: (context, eventsSnapshot) {
                if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                  return const _HistorySkeleton();
                }
                if (eventsSnapshot.hasError) {
                  return Text(
                    'Impossible de charger l’historique.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }

                final events = eventsSnapshot.data ?? const <CommandEvent>[];
                final hasAnyEvent = events.isNotEmpty;
                final grouped = _groupByCycle(events);
                final currentKey = command.cycleKeyAt(DateTime.now().toUtc());

                final visualization = switch (command.frequency) {
                  Frequency.daily => _DailyCalendar(
                      anchorUtc: anchorUtc,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                    ),
                  Frequency.weekly => _WeeklyList(
                      anchorUtc: anchorUtc,
                      grouped: grouped,
                      currentKey: currentKey,
                      target: command.target,
                      createdAtUtc: effectiveCreatedAtUtc,
                    ),
                  Frequency.monthly => _MonthlyGrid(
                      year: anchorUtc.year,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                    ),
                  Frequency.yearly => _YearlyBar(
                      year: anchorUtc.year,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                    ),
                };

                final summary = const BuildCycleSummaryUseCase().execute(
                  frequency: command.frequency,
                  anchorUtc: anchorUtc,
                  grouped: grouped,
                  currentKey: currentKey,
                  createdAtUtc: effectiveCreatedAtUtc,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!hasAnyEvent)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Aucun historique pour cette période. Continuez, chaque action compte !',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    visualization,
                    const SizedBox(height: 14),
                    _SummaryCard(summary: summary),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }
}

Map<String, List<CommandEvent>> _groupByCycle(List<CommandEvent> events) {
  final map = <String, List<CommandEvent>>{};
  for (final event in events) {
    map.putIfAbsent(event.cycleKey, () => <CommandEvent>[]).add(event);
  }
  return map;
}

bool _hasComplete(List<CommandEvent> events) {
  return events.any((e) => e.type == CommandEventType.complete);
}

String _nextResetText(Frequency frequency, DateTime nowUtc) {
  final now = nowUtc.toUtc();
  switch (frequency) {
    case Frequency.daily:
      return 'Reset demain';
    case Frequency.weekly:
      return 'Reset lundi prochain';
    case Frequency.monthly:
      return 'Reset le 1er du mois prochain';
    case Frequency.yearly:
      return 'Reset le 1er janvier ${now.year + 1}';
  }
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

String _monthLabel(int month) {
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

class _HistorySkeleton extends StatefulWidget {
  const _HistorySkeleton();

  @override
  State<_HistorySkeleton> createState() => _HistorySkeletonState();
}

class _HistorySkeletonState extends State<_HistorySkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.08 + (0.08 * _controller.value);
        final color = Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);
        return Column(
          children: List.generate(
            4,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DailyCalendar extends StatelessWidget {
  final DateTime anchorUtc;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;

  const _DailyCalendar({
    required this.anchorUtc,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    final start = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final end = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    final days = end.difference(start).inDays;

    final now = DateTime.now().toUtc();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final day = DateTime.utc(anchorUtc.year, anchorUtc.month, index + 1);
        if (!_isCycleVisible(
          frequency: Frequency.daily,
          cycleStartUtc: day,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
        final events = grouped[key] ?? const <CommandEvent>[];
        final success = _hasComplete(events);
        final isCurrent = key == currentKey;
        final isPast = day.isBefore(DateTime.utc(now.year, now.month, now.day));
        final status = _statusForCycle(
          isSuccess: success,
          isCurrent: isCurrent,
          isPast: isPast,
        );
        final style = _styleForStatus(status, context);
        return Semantics(
          label: 'Jour ${day.day} ${_monthLabel(day.month)} ${day.year} : ${_statusSemantics(status)}',
          child: Container(
            decoration: BoxDecoration(
              color: style.backgroundColor,
              border: Border.all(color: style.indicatorColor.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: style.indicatorColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WeeklyList extends StatelessWidget {
  final DateTime anchorUtc;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final int target;
  final DateTime createdAtUtc;

  const _WeeklyList({
    required this.anchorUtc,
    required this.grouped,
    required this.currentKey,
    required this.target,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    final weeks = <String>[];
    final monthStart = DateTime.utc(anchorUtc.year, anchorUtc.month, 1);
    final monthEnd = anchorUtc.month == 12
        ? DateTime.utc(anchorUtc.year + 1, 1, 1)
        : DateTime.utc(anchorUtc.year, anchorUtc.month + 1, 1);
    final currentWeekStart =
        CycleKeyGenerator.cycleStartUtc(Frequency.weekly, DateTime.now().toUtc());

    DateTime cursor = monthStart;
    while (cursor.isBefore(monthEnd)) {
      final weekKey = CycleKeyGenerator.forFrequency(
        frequency: Frequency.weekly,
        atUtc: cursor,
      );
      if (!weeks.contains(weekKey)) weeks.add(weekKey);
      cursor = cursor.add(const Duration(days: 7));
    }

    return Column(
      children: weeks.map((weekKey) {
        final weekStart = _weekStartFromCycleKey(weekKey);
        if (!_isCycleVisible(
          frequency: Frequency.weekly,
          cycleStartUtc: weekStart,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final events = grouped[weekKey] ?? const <CommandEvent>[];
        final increments = events.where((e) => e.type == CommandEventType.increment).length;
        final progress = events.isEmpty
            ? 0
            : events.map((e) => e.progressAfterAction).reduce((a, b) => a > b ? a : b);
        final progressRatio = target <= 0 ? 0.0 : (progress / target).clamp(0.0, 1.0);
        final success = _hasComplete(events);
        final status = _statusForCycle(
          isSuccess: success,
          isCurrent: weekKey == currentKey,
          isPast: weekStart.isBefore(currentWeekStart),
        );
        final style = _styleForStatus(status, context);
        final textColor = _accessibleForegroundColor(
          backgroundColor: style.backgroundColor,
          context: context,
        );
        final weekNumber = _weekNumberFromCycleKey(weekKey);

        return Semantics(
          label: 'Semaine $weekNumber : ${_statusSemantics(status)}',
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: style.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: style.indicatorColor.withValues(alpha: 0.55)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    weekKey,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: textColor,
                        ),
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: progressRatio,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _progressColorForRatio(context, progressRatio),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '$progress/$target',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 12),
                      Wrap(
                        spacing: 4,
                        children: List.generate(
                          increments.clamp(0, 20),
                          (_) => Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.circle, size: 12, color: style.indicatorColor),
                      const SizedBox(width: 4),
                      Icon(style.stateIcon, size: 14, color: textColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

Color _progressColorForRatio(BuildContext context, double ratio) {
  final semanticColors = Theme.of(context).extension<AppSemanticColors>();
  if (ratio < 0.5) {
    return semanticColors?.progressLow ?? Theme.of(context).colorScheme.error;
  }
  if (ratio < 0.8) {
    return semanticColors?.progressMedium ?? Theme.of(context).colorScheme.tertiary;
  }
  return semanticColors?.progressHigh ?? Theme.of(context).colorScheme.primary;
}

class _MonthlyGrid extends StatelessWidget {
  final int year;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;

  const _MonthlyGrid({
    required this.year,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().toUtc();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final month = index + 1;
        final cycleStart = DateTime.utc(year, month, 1);
        if (!_isCycleVisible(
          frequency: Frequency.monthly,
          cycleStartUtc: cycleStart,
          createdAtUtc: createdAtUtc,
        )) {
          return const SizedBox.shrink();
        }
        final key = '$year-${month.toString().padLeft(2, '0')}';
        final success = _hasComplete(grouped[key] ?? const <CommandEvent>[]);
        final isCurrent = key == currentKey;
        final isPast = DateTime.utc(year, month, 1).isBefore(DateTime.utc(now.year, now.month, 1));
        final status = _statusForCycle(
          isSuccess: success,
          isCurrent: isCurrent,
          isPast: isPast,
        );
        final style = _styleForStatus(status, context);
        final textColor = _accessibleForegroundColor(
          backgroundColor: style.backgroundColor,
          context: context,
        );
        return Semantics(
          label: '${_monthLabel(month)} $year : ${_statusSemantics(status)}',
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: style.backgroundColor,
              border: Border.all(color: style.indicatorColor.withValues(alpha: 0.55)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(style.stateIcon, size: 12, color: textColor),
                const SizedBox(width: 4),
                Text(
                  month.toString().padLeft(2, '0'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _YearlyBar extends StatelessWidget {
  final int year;
  final Map<String, List<CommandEvent>> grouped;
  final String currentKey;
  final DateTime createdAtUtc;

  const _YearlyBar({
    required this.year,
    required this.grouped,
    required this.currentKey,
    required this.createdAtUtc,
  });

  @override
  Widget build(BuildContext context) {
    if (!_isCycleVisible(
      frequency: Frequency.yearly,
      cycleStartUtc: DateTime.utc(year, 1, 1),
      createdAtUtc: createdAtUtc,
    )) {
      return const SizedBox.shrink();
    }
    final key = '$year';
    final success = _hasComplete(grouped[key] ?? const <CommandEvent>[]);
    final nowYear = DateTime.now().toUtc().year;
    final status = _statusForCycle(
      isSuccess: success,
      isCurrent: key == currentKey,
      isPast: year < nowYear,
    );
    final style = _styleForStatus(status, context);
    final textColor = _accessibleForegroundColor(
      backgroundColor: style.backgroundColor,
      context: context,
    );
    return Semantics(
      label: 'Année $year : ${_statusSemantics(status)}',
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: style.backgroundColor,
          border: Border.all(color: style.indicatorColor.withValues(alpha: 0.55)),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 10, color: style.indicatorColor),
            const SizedBox(width: 4),
            Icon(style.stateIcon, size: 12, color: textColor),
            const SizedBox(width: 6),
            Text(
              '$year',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

bool _isCycleVisible({
  required Frequency frequency,
  required DateTime cycleStartUtc,
  required DateTime createdAtUtc,
}) {
  final firstVisibleCycleStart =
      CycleKeyGenerator.cycleStartUtc(frequency, createdAtUtc.toUtc());
  return !cycleStartUtc.toUtc().isBefore(firstVisibleCycleStart);
}

DateTime _weekStartFromCycleKey(String cycleKey) {
  final match = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(cycleKey);
  if (match == null) {
    return DateTime.utc(1970, 1, 1);
  }
  final year = int.parse(match.group(1)!);
  final week = int.parse(match.group(2)!);
  return _isoWeekStartUtc(year, week);
}

DateTime _isoWeekStartUtc(int year, int week) {
  final jan4 = DateTime.utc(year, 1, 4);
  final mondayWeek1 = jan4.subtract(Duration(days: jan4.weekday - DateTime.monday));
  return mondayWeek1.add(Duration(days: (week - 1) * 7));
}

enum _CycleVisualStatus {
  success,
  failed,
  current,
}

_CycleVisualStatus _statusForCycle({
  required bool isSuccess,
  required bool isCurrent,
  required bool isPast,
}) {
  if (isSuccess) return _CycleVisualStatus.success;
  if (isCurrent) return _CycleVisualStatus.current;
  if (isPast) return _CycleVisualStatus.failed;
  return _CycleVisualStatus.current;
}

class _CycleStyle {
  final Color backgroundColor;
  final Color indicatorColor;
  final IconData stateIcon;

  const _CycleStyle({
    required this.backgroundColor,
    required this.indicatorColor,
    required this.stateIcon,
  });
}

_CycleStyle _styleForStatus(_CycleVisualStatus status, BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final semanticColors = Theme.of(context).extension<AppSemanticColors>();
  switch (status) {
    case _CycleVisualStatus.success:
      return _CycleStyle(
        backgroundColor: semanticColors?.successBackground ??
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.12),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.successIndicator ?? scheme.primary,
        stateIcon: Icons.check_rounded,
      );
    case _CycleVisualStatus.failed:
      return _CycleStyle(
        backgroundColor: semanticColors?.failedBackground ??
            Color.alphaBlend(
              scheme.error.withValues(alpha: 0.12),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.failedIndicator ?? scheme.error,
        stateIcon: Icons.close_rounded,
      );
    case _CycleVisualStatus.current:
      return _CycleStyle(
        backgroundColor: semanticColors?.currentBackground ??
            Color.alphaBlend(
              scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              scheme.surface,
            ),
        indicatorColor: semanticColors?.currentIndicator ?? scheme.outline,
        stateIcon: Icons.schedule_rounded,
      );
  }
}

String _statusSemantics(_CycleVisualStatus status) {
  switch (status) {
    case _CycleVisualStatus.success:
      return 'objectif atteint';
    case _CycleVisualStatus.failed:
      return 'objectif non atteint';
    case _CycleVisualStatus.current:
      return 'en cours';
  }
}

int _weekNumberFromCycleKey(String cycleKey) {
  final match = RegExp(r'^\d{4}-[SW](\d{2})$').firstMatch(cycleKey);
  if (match == null) return 0;
  return int.parse(match.group(1)!);
}

Color _accessibleForegroundColor({
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
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = channel(color.r);
  final g = channel(color.g);
  final b = channel(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

class _SummaryCard extends StatelessWidget {
  final CycleSummary summary;

  const _SummaryCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(child: Text('🟢 ${summary.success} cycles réussis')),
            Expanded(child: Text('🔴 ${summary.failed} cycles échoués')),
            Expanded(
              child: Text(
                'Complétion: ${summary.completionRate}%',
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
