import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/entities/command_events_period.dart';
import '../../domain/repositories/command_event_repository.dart';
import '../../domain/usecases/build_cycle_summary_usecase.dart';
import '../state/command_provider.dart';
import '../state/cycle_note_provider.dart';
import '../utils/cycle_keys_for_detail_period.dart';
import '../utils/cycle_visual_style.dart';
import '../widgets/cycle_summary_card.dart';
import '../widgets/cycle_visualizations/daily_calendar.dart';
import '../widgets/cycle_visualizations/monthly_grid.dart';
import '../widgets/cycle_visualizations/weekly_list.dart';
import '../widgets/cycle_visualizations/yearly_bar.dart';
import '../widgets/command_streak_from_repository.dart';
import '../widgets/dynamic_progress_bar.dart';
import '../widgets/history_skeleton.dart';

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

class _DetailContent extends StatefulWidget {
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
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  late Future<DateTime?> _createdAtFuture;

  @override
  void initState() {
    super.initState();
    final eventRepository = context.read<CommandEventRepository>();
    final command = widget.command;
    _createdAtFuture = command.createdAt == null
        ? eventRepository.firstEventAtUtc(command.id)
        : Future<DateTime?>.value(command.createdAt!.toUtc());
  }

  @override
  void didUpdateWidget(_DetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.command.id != oldWidget.command.id) {
      final eventRepository = context.read<CommandEventRepository>();
      final command = widget.command;
      _createdAtFuture = command.createdAt == null
          ? eventRepository.firstEventAtUtc(command.id)
          : Future<DateTime?>.value(command.createdAt!.toUtc());
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventRepository = context.read<CommandEventRepository>();
    final command = widget.command;
    final period = widget.period;
    final anchorUtc = widget.anchorUtc;
    final nextResetText = _nextResetText(command.frequency, DateTime.now().toUtc());
    final periodLabel = (command.frequency == Frequency.monthly || command.frequency == Frequency.yearly)
        ? '${anchorUtc.year}'
        : '${monthLabel(anchorUtc.month)} ${anchorUtc.year}';

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
                            '${frequencyLabel(command.frequency)} · objectif ${command.target}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CommandStreakFromRepository(
                  command: command,
                  compact: false,
                  titleIndent: 44,
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
              onPressed: widget.onPrevious,
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
              onPressed: widget.onNext,
              icon: const Icon(Icons.chevron_right_rounded),
              tooltip: 'Période suivante',
            ),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<DateTime?>(
          future: _createdAtFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const HistorySkeleton();
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

            return _CycleNoteSubscription(
              commandId: command.id,
              frequency: command.frequency,
              anchorUtc: anchorUtc,
              createdAtUtc: effectiveCreatedAtUtc,
              child: StreamBuilder<List<CommandEvent>>(
                stream: eventRepository.watchEvents(command.id, period: period),
                builder: (context, eventsSnapshot) {
                  if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                    return const HistorySkeleton();
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
                  final cycleNotes = context.watch<CycleNoteProvider>().notes;

                  final visualization = switch (command.frequency) {
                    Frequency.daily => DailyCalendar(
                        anchorUtc: anchorUtc,
                        grouped: grouped,
                        currentKey: currentKey,
                        createdAtUtc: effectiveCreatedAtUtc,
                        commandId: command.id,
                        notes: cycleNotes,
                      ),
                    Frequency.weekly => WeeklyList(
                        anchorUtc: anchorUtc,
                        grouped: grouped,
                        currentKey: currentKey,
                        target: command.target,
                        createdAtUtc: effectiveCreatedAtUtc,
                        commandId: command.id,
                        notes: cycleNotes,
                      ),
                    Frequency.monthly => MonthlyGrid(
                        year: anchorUtc.year,
                        grouped: grouped,
                        currentKey: currentKey,
                        createdAtUtc: effectiveCreatedAtUtc,
                        commandId: command.id,
                        notes: cycleNotes,
                      ),
                    Frequency.yearly => YearlyBar(
                        year: anchorUtc.year,
                        grouped: grouped,
                        currentKey: currentKey,
                        createdAtUtc: effectiveCreatedAtUtc,
                        commandId: command.id,
                        notes: cycleNotes,
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
                      SummaryCard(summary: summary),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CycleNoteSubscription extends StatefulWidget {
  final String commandId;
  final Frequency frequency;
  final DateTime anchorUtc;
  final DateTime createdAtUtc;
  final Widget child;

  const _CycleNoteSubscription({
    required this.commandId,
    required this.frequency,
    required this.anchorUtc,
    required this.createdAtUtc,
    required this.child,
  });

  @override
  State<_CycleNoteSubscription> createState() => _CycleNoteSubscriptionState();
}

class _CycleNoteSubscriptionState extends State<_CycleNoteSubscription> {
  CycleNoteProvider? _cycleNoteProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cycleNoteProvider = context.read<CycleNoteProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _subscribe();
    });
  }

  @override
  void didUpdateWidget(covariant _CycleNoteSubscription oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.commandId != oldWidget.commandId ||
        widget.frequency != oldWidget.frequency ||
        widget.anchorUtc != oldWidget.anchorUtc ||
        widget.createdAtUtc != oldWidget.createdAtUtc) {
      _subscribe();
    }
  }

  void _subscribe() {
    final provider = _cycleNoteProvider;
    if (provider == null) return;
    final keys = cycleKeysForDetailPeriod(
      frequency: widget.frequency,
      anchorUtc: widget.anchorUtc,
      createdAtUtc: widget.createdAtUtc,
    );
    provider.subscribe(
      commandId: widget.commandId,
      cycleKeys: keys,
    );
  }

  @override
  void dispose() {
    _cycleNoteProvider?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Map<String, List<CommandEvent>> _groupByCycle(List<CommandEvent> events) {
  final map = <String, List<CommandEvent>>{};
  for (final event in events) {
    map.putIfAbsent(event.cycleKey, () => <CommandEvent>[]).add(event);
  }
  return map;
}

String _nextResetText(Frequency frequency, DateTime nowUtc) {
  final utc = nowUtc.toUtc();
  switch (frequency) {
    case Frequency.daily:
      if (utc.toLocal().hour >= 22) {
        return 'Reset demain';
      }
      return 'Reset demain à minuit UTC';
    case Frequency.weekly:
      final dayStart = DateTime.utc(utc.year, utc.month, utc.day);
      final offset = dayStart.weekday - DateTime.monday;
      final thisMonday = dayStart.subtract(Duration(days: offset));
      final nextMonday = thisMonday.add(const Duration(days: 7));
      return 'Reset le lundi ${nextMonday.day} ${monthLabel(nextMonday.month)}';
    case Frequency.monthly:
      final nextFirst = utc.month == 12
          ? DateTime.utc(utc.year + 1, 1, 1)
          : DateTime.utc(utc.year, utc.month + 1, 1);
      return 'Reset le 1er ${monthLabel(nextFirst.month)}';
    case Frequency.yearly:
      return 'Reset le 1er janvier ${utc.year + 1}';
  }
}
