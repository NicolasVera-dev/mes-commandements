import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../app/localization/localization.dart';
import '../../../auth/presentation/pages/account_settings_page.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../domain/entities/journal_day.dart';
import '../../domain/entities/journal_task.dart';
import '../state/journal_provider.dart';
import '../widgets/journal_progress_card.dart';
import '../widgets/journal_review_sheet.dart';
import '../widgets/journal_task_card.dart';
import '../widgets/journal_task_sheet.dart';
import '../widgets/journal_week_overview.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});
  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> with WidgetsBindingObserver {
  late JournalDay _day;
  bool _followingToday = true;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _day = context.read<JournalProvider>().today;
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(milliseconds: 100),
      _refreshDay,
    );
  }

  void _refreshDay() {
    if (!mounted) return;
    final provider = context.read<JournalProvider>();
    if (_followingToday) setState(() => _day = provider.today);
    provider.refreshDay();
    _scheduleMidnight();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshDay();
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _selectDay(JournalDay day) => setState(() {
    _day = day;
    _followingToday = day == context.read<JournalProvider>().today;
  });

  Future<JournalDay?> _pickDay({
    bool futureOnly = false,
    JournalDay? initial,
  }) async {
    final today = context.read<JournalProvider>().today;
    final first = futureOnly ? today : JournalDay.fromDate(DateTime(2020));
    final date = await showDatePicker(
      context: context,
      initialDate: (initial ?? _day).date,
      firstDate: first.date,
      lastDate: today.add(3650).date,
    );
    return date == null ? null : JournalDay.fromDate(date);
  }

  Future<bool> _perform(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.journalError)));
      }
      return false;
    }
  }

  Future<void> _toggle(JournalTask task, bool done) async {
    final provider = context.read<JournalProvider>();
    if (await _perform(() => provider.toggle(task.id, done)) &&
        done &&
        mounted) {
      unawaited(HapticFeedback.lightImpact());
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              provider.summary(provider.today).score == 100
                  ? context.l10n.journalAllDoneFeedback
                  : context.l10n.journalCompletedFeedback,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  Future<void> _remove(JournalTask task) async {
    final provider = context.read<JournalProvider>();
    JournalTask? removed;
    if (!await _perform(() async {
          removed = await provider.remove(task.id);
        }) ||
        !mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.l10n.journalRemoved),
          action: SnackBarAction(
            label: context.l10n.journalUndo,
            onPressed: () => _perform(() => provider.restore(removed!)),
          ),
        ),
      );
  }

  Future<void> _action(JournalTask task, JournalTaskAction action) async {
    final provider = context.read<JournalProvider>();
    switch (action) {
      case JournalTaskAction.edit:
        await showJournalTaskSheet(context, day: _day, task: task);
      case JournalTaskAction.reschedule:
        final target = await _pickDay(
          futureOnly: true,
          initial: task.scheduledDay.isBefore(provider.today)
              ? provider.today
              : task.scheduledDay,
        );
        if (target != null && mounted) {
          await _perform(() => provider.reschedule(task.id, target));
        }
      case JournalTaskAction.delete:
        await _remove(task);
    }
  }

  Widget _taskRow(
    JournalTask task, {
    required bool past,
    required bool busy,
    required bool today,
  }) {
    final card = JournalTaskCard(
      task: task,
      day: _day,
      isToday: today,
      readOnly: past,
      busy: busy,
      onToggle: (done) => _toggle(task, done),
      onAction: (action) => _action(task, action),
    );
    if (past || busy) return card;
    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        await _remove(task);
        return false;
      },
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();
    final strings = context.l10n;
    final theme = Theme.of(context);
    final dates = MaterialLocalizations.of(context);
    final today = provider.today;
    final past = _day.isBefore(today);
    final future = _day.isAfter(today);
    final summary = provider.summary(_day);
    final pending = summary.pending;
    final busy = provider.isSaving || provider.hasError || provider.isLoading;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        toolbarHeight: 68,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(strings.journalTitle),
        actions: [
          IconButton(
            tooltip: strings.journalCalendar,
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () async {
              final day = await _pickDay();
              if (day != null && mounted) _selectDay(day);
            },
          ),
          if (provider.isConnected)
            IconButton(
              tooltip: strings.parametresDuCompte,
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AccountSettingsPage(),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: provider.isConnected && !past
          ? FloatingActionButton.extended(
              onPressed: busy
                  ? null
                  : () => showJournalTaskSheet(context, day: _day),
              icon: const Icon(Icons.add),
              label: Text(strings.journalAddTask),
            )
          : null,
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !provider.isConnected
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(strings.journalSignIn, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginPage(),
                        ),
                      ),
                      child: Text(strings.journalSignInAction),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (provider.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(strings.journalLoadError),
                              TextButton(
                                onPressed: provider.retry,
                                child: Text(strings.journalRetry),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: strings.journalPreviousDay,
                        icon: const Icon(Icons.chevron_left),
                        onPressed:
                            _day.date.year <= 2020 &&
                                _day.date.month == 1 &&
                                _day.date.day == 1
                            ? null
                            : () => _selectDay(_day.add(-1)),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              dates.formatFullDate(_day.date),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleSmall,
                            ),
                            if (_day != today)
                              TextButton(
                                onPressed: () => _selectDay(today),
                                child: Text(strings.journalToday),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: strings.journalNextDay,
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _day == today.add(3650)
                            ? null
                            : () => _selectDay(_day.add(1)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  JournalProgressCard(summary: summary, isFuture: future),
                  const SizedBox(height: 12),
                  if (!future)
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => showJournalReviewSheet(context, _day),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: Text(strings.journalReviewAction),
                    ),
                  if (provider.reflection(_day) case final reflection?) ...[
                    if (reflection.mood != null || reflection.note.isNotEmpty)
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reflection.mood case final mood?)
                                Text(
                                  journalMoodLabel(strings, mood),
                                  style: theme.textTheme.labelLarge,
                                ),
                              if (reflection.note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(reflection.note),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  if (summary.tasks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 12,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.checklist_rounded,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            past
                                ? strings.journalEmptyPast
                                : strings.journalEmptyTitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium,
                          ),
                          if (!past)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                strings.journalEmptyBody,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (pending.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        strings.journalPending(pending.length),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (!past && pending.length > 1)
                      Text(
                        strings.journalReorderHint,
                        style: theme.textTheme.bodySmall,
                      ),
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: pending.length,
                      onReorderItem: (oldIndex, newIndex) {
                        if (past || busy) return;
                        final reordered = [...pending];
                        final task = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, task);
                        _perform(
                          () => provider.reorder(
                            reordered.map((t) => t.id).toList(),
                          ),
                        );
                      },
                      itemBuilder: (_, index) {
                        final task = pending[index];
                        final card = _taskRow(
                          task,
                          past: past,
                          busy: busy,
                          today: !past && !future,
                        );
                        return !past && !busy
                            ? ReorderableDelayedDragStartListener(
                                key: ValueKey(task.id),
                                index: index,
                                child: card,
                              )
                            : KeyedSubtree(key: ValueKey(task.id), child: card);
                      },
                    ),
                  ],
                  if (summary.completed.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Text(
                        strings.journalDone(summary.completed.length),
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ...summary.completed.map(
                      (task) => _taskRow(
                        task,
                        past: past,
                        busy: busy,
                        today: !past && !future,
                      ),
                    ),
                  ],
                  if (summary.tasks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        past
                            ? strings.journalPastHint
                            : future
                            ? strings.journalFutureHint
                            : strings.journalCarryHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  JournalWeekOverview(today: today, onSelectDay: _selectDay),
                ],
              ),
            ),
    );
  }
}
