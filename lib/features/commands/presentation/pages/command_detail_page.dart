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
import '../widgets/command_confirmation_dialogs.dart';
import '../widgets/cycle_summary_card.dart';
import '../widgets/cycle_visualizations/daily_calendar.dart';
import '../widgets/cycle_visualizations/monthly_grid.dart';
import '../widgets/cycle_visualizations/weekly_list.dart';
import '../widgets/cycle_visualizations/yearly_bar.dart';
import '../widgets/command_streak_from_repository.dart';
import '../widgets/command_pause_dialog.dart';
import '../widgets/command_visibility_dialog.dart';
import '../widgets/dynamic_progress_bar.dart';
import '../widgets/history_skeleton.dart';
import '../../../../app/localization/localization.dart';

enum _CommandDetailAction { pause, visibility, reset, delete }

class CommandDetailPage extends StatefulWidget {
  final String commandId;

  const CommandDetailPage({super.key, required this.commandId});

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
        final y = _anchorUtc.month == 12
            ? _anchorUtc.year + 1
            : _anchorUtc.year;
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
    if (frequency == Frequency.weekly) {
      return CommandEventsPeriod.forIsoWeeksTouchingCalendarMonthUtc(
        _anchorUtc,
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
    final now = DateTime.now().toUtc();
    final isPaused = command?.isPausedAt(now) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.detailDuCommandement),
        actions: [
          if (command != null)
            PopupMenuButton<_CommandDetailAction>(
              tooltip: context.l10n.actionsDuCommandement,
              enabled: !provider.isMutating,
              onSelected: (action) => _handleAction(action, provider, command),
              itemBuilder: (context) => [
                if (!command.isHidden)
                  PopupMenuItem(
                    value: _CommandDetailAction.pause,
                    child: Text(
                      isPaused
                          ? context.l10n.reprendre
                          : context.l10n.mettreEnPause,
                    ),
                  ),
                if (!isPaused && !command.isHidden)
                  PopupMenuItem(
                    value: _CommandDetailAction.reset,
                    enabled: command.isActiveOnDayUtc(now),
                    child: Text(context.l10n.reinitialiser),
                  ),
                PopupMenuItem(
                  value: _CommandDetailAction.visibility,
                  child: Text(
                    command.isHidden
                        ? context.l10n.showCommandAction
                        : context.l10n.hideCommandAction,
                  ),
                ),
                PopupMenuItem(
                  value: _CommandDetailAction.delete,
                  child: Text(context.l10n.supprimer),
                ),
              ],
            ),
        ],
      ),
      body: command == null
          ? Center(
              child: Text(
                context.l10n.commandementIntrouvable,
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

  Future<void> _handleAction(
    _CommandDetailAction action,
    CommandProvider provider,
    Command command,
  ) async {
    if (action == _CommandDetailAction.visibility) {
      final success = await showCommandVisibilityDialog(context, command);
      if (success && !command.isHidden && mounted) {
        await Navigator.of(context).maybePop();
      }
      return;
    }
    if (action == _CommandDetailAction.pause) {
      await showCommandPauseDialog(context, command);
      return;
    }
    final deleting = action == _CommandDetailAction.delete;
    final confirmed = deleting
        ? await confirmCommandDeletion(context)
        : await confirmCommandReset(context);
    if (!confirmed || !mounted) return;

    final success = deleting
        ? await provider.deleteCommand(command.id)
        : await provider.resetProgress(command.id);
    if (!mounted) return;
    if (success && deleting) {
      await Navigator.of(context).maybePop();
    } else if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.systemMessage(
              provider.syncErrorMessage ??
                  context.l10n.cetteActionEstIndisponiblePourLeMoment,
            ),
          ),
        ),
      );
    }
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

  Future<void> _confirmPastCycleCompletion({
    required String cycleKey,
    required String cycleLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.confirmation),
        content: Text(context.l10n.marquerCommeComplete2(cycleLabel)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.confirmer),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<CommandProvider>().completePastCycle(
      commandId: widget.command.id,
      cycleKey: cycleKey,
    );
  }

  Future<void> _confirmPastCycleUncompletion({
    required String cycleKey,
    required String cycleLabel,
  }) async {
    final cycleLabelWithPreposition = _withDePrefix(cycleLabel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.confirmation),
        content: Text(
          context.l10n.retirerLaCompletion2(cycleLabelWithPreposition),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.annuler),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.confirmer),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    context.read<CommandProvider>().uncompletePastCycle(
      commandId: widget.command.id,
      cycleKey: cycleKey,
    );
  }

  String _withDePrefix(String label) {
    if (context.l10n.localeName.startsWith('en')) return label;
    final trimmed = label.trimLeft();
    if (trimmed.startsWith('le ')) {
      return 'du ${trimmed.substring(3)}';
    }
    if (trimmed.startsWith('les ')) {
      return 'des ${trimmed.substring(4)}';
    }
    if (trimmed.startsWith('la ')) {
      return context.l10n.deLa(trimmed.substring(3));
    }
    if (trimmed.startsWith("l'") || trimmed.startsWith('l’')) {
      return 'de $trimmed';
    }
    const vowelsAndMuteH = 'aàâäeéèêëiîïoôöuùûüyÿh';
    final first = trimmed.isEmpty ? '' : trimmed[0].toLowerCase();
    if (vowelsAndMuteH.contains(first)) {
      return "d'$trimmed";
    }
    return 'de $trimmed';
  }

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
    final description = command.description.trim();
    final period = widget.period;
    final anchorUtc = widget.anchorUtc;
    final now = DateTime.now().toUtc();
    final isPaused = command.isPausedAt(now);
    final nextResetText = _nextResetText(
      command.frequency,
      DateTime.now().toUtc(),
      strings: context.l10n,
    );
    final periodLabel =
        (command.frequency == Frequency.monthly ||
            command.frequency == Frequency.yearly)
        ? '${anchorUtc.year}'
        : '${monthLabel(anchorUtc.month, strings: context.l10n)} ${anchorUtc.year}';

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
                        child: Text(
                          command.emoji,
                          style: const TextStyle(fontSize: 34),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            command.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${frequencyLabel(command.frequency, strings: context.l10n)} · objectif ${command.target}',
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
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: 12),
                DynamicProgressBar(
                  progress: command.progress,
                  target: command.target,
                  accentTintColor: command.accentColorValue == null
                      ? null
                      : Color(command.accentColorValue!),
                ),
                const SizedBox(height: 8),
                if (isPaused)
                  CommandPauseStatus(command: command)
                else
                  Text(
                    nextResetText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
              tooltip: context.l10n.periodePrecedente,
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
              tooltip: context.l10n.periodeSuivante,
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
                context.l10n.impossibleDeChargerLhistorique,
                style: Theme.of(context).textTheme.bodyMedium,
              );
            }

            final effectiveCreatedAtUtc = snapshot.data?.toUtc();
            if (effectiveCreatedAtUtc == null) {
              return Text(
                context
                    .l10n
                    .aucunHistoriquePourCeCommandementPourLeMomentContinuez,
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
                  if (eventsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const HistorySkeleton();
                  }
                  if (eventsSnapshot.hasError) {
                    return Text(
                      context.l10n.impossibleDeChargerLhistorique,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  }

                  final events = eventsSnapshot.data ?? const <CommandEvent>[];
                  final hasAnyEvent = events.isNotEmpty;
                  final grouped = _groupByCycle(events);
                  final currentKey = command.cycleKeyAt(now);
                  bool isCyclePaused(DateTime start) =>
                      command.cycleKeyAt(start) == currentKey
                      ? isPaused
                      : command.wasPausedAtCycleEnd(start);
                  final cycleNotes = context.watch<CycleNoteProvider>().notes;

                  final visualization = switch (command.frequency) {
                    Frequency.daily => DailyCalendar(
                      anchorUtc: anchorUtc,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                      commandId: command.id,
                      isCyclePaused: isCyclePaused,
                      activeWeekdays: command.activeWeekdays,
                      notes: cycleNotes,
                      onCompletePastCycle: _confirmPastCycleCompletion,
                      onUncompletePastCycle: _confirmPastCycleUncompletion,
                    ),
                    Frequency.weekly => WeeklyList(
                      anchorUtc: anchorUtc,
                      grouped: grouped,
                      currentKey: currentKey,
                      target: command.target,
                      createdAtUtc: effectiveCreatedAtUtc,
                      commandId: command.id,
                      isCyclePaused: isCyclePaused,
                      notes: cycleNotes,
                      onCompletePastCycle: _confirmPastCycleCompletion,
                      onUncompletePastCycle: _confirmPastCycleUncompletion,
                    ),
                    Frequency.monthly => MonthlyGrid(
                      year: anchorUtc.year,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                      commandId: command.id,
                      isCyclePaused: isCyclePaused,
                      notes: cycleNotes,
                      onCompletePastCycle: _confirmPastCycleCompletion,
                      onUncompletePastCycle: _confirmPastCycleUncompletion,
                    ),
                    Frequency.yearly => YearlyBar(
                      year: anchorUtc.year,
                      grouped: grouped,
                      currentKey: currentKey,
                      createdAtUtc: effectiveCreatedAtUtc,
                      commandId: command.id,
                      isCyclePaused: isCyclePaused,
                      notes: cycleNotes,
                      onCompletePastCycle: _confirmPastCycleCompletion,
                      onUncompletePastCycle: _confirmPastCycleUncompletion,
                    ),
                  };

                  final summary = const BuildCycleSummaryUseCase().execute(
                    frequency: command.frequency,
                    anchorUtc: anchorUtc,
                    grouped: grouped,
                    currentKey: currentKey,
                    createdAtUtc: effectiveCreatedAtUtc,
                    activeWeekdays: command.activeWeekdays,
                    wasPausedAtCycleEnd: command.wasPausedAtCycleEnd,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!hasAnyEvent)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            context
                                .l10n
                                .aucunHistoriquePourCettePeriodeContinuezChaqueActionCompte,
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
    provider.subscribe(commandId: widget.commandId, cycleKeys: keys);
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

String _nextResetText(
  Frequency frequency,
  DateTime nowUtc, {
  AppLocalizations? strings,
}) {
  final l10n = strings ?? lookupAppLocalizations(const Locale('fr'));

  final utc = nowUtc.toUtc();
  switch (frequency) {
    case Frequency.daily:
      if (utc.toLocal().hour >= 22) {
        return l10n.resetDemain;
      }
      return l10n.resetDemainAMinuitUtc;
    case Frequency.weekly:
      final dayStart = DateTime.utc(utc.year, utc.month, utc.day);
      final offset = dayStart.weekday - DateTime.monday;
      final thisMonday = dayStart.subtract(Duration(days: offset));
      final nextMonday = thisMonday.add(const Duration(days: 7));
      return l10n.resetLeLundi(nextMonday.day, monthLabel(nextMonday.month));
    case Frequency.monthly:
      final nextFirst = utc.month == 12
          ? DateTime.utc(utc.year + 1, 1, 1)
          : DateTime.utc(utc.year, utc.month + 1, 1);
      return l10n.resetLe1er(monthLabel(nextFirst.month));
    case Frequency.yearly:
      return l10n.resetLe1erJanvier(utc.year + 1);
  }
}
