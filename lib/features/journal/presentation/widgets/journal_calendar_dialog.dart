import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../app/app_theme.dart';
import '../../../../app/localization/localization.dart';
import '../../domain/entities/journal_day.dart';
import '../../domain/services/journal_day_status.dart';
import '../state/journal_provider.dart';

Future<JournalDay?> showJournalCalendar(
  BuildContext context,
  JournalDay initial,
) => showDialog<JournalDay>(
  context: context,
  builder: (_) => _JournalCalendar(initial: initial),
);

class _JournalCalendar extends StatefulWidget {
  final JournalDay initial;
  const _JournalCalendar({required this.initial});
  @override
  State<_JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends State<_JournalCalendar> {
  late DateTime _focused;
  @override
  void initState() {
    super.initState();
    _focused = widget.initial.date;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournalProvider>();
    final strings = context.l10n;
    final theme = Theme.of(context);
    final semantic = theme.extension<AppSemanticColors>();
    final green = semantic?.successIndicator ?? theme.colorScheme.primary;
    final red = semantic?.failedIndicator ?? theme.colorScheme.error;
    final today = provider.today;
    final first = DateTime(2000);
    final last = today.add(3650).date;
    String label(JournalDayStatus status) => switch (status) {
      JournalDayStatus.success => strings.journalCalendarSuccess,
      JournalDayStatus.failure => strings.journalCalendarFailure,
      JournalDayStatus.empty => strings.journalCalendarEmpty,
      JournalDayStatus.planned => strings.journalCalendarPlanned,
      JournalDayStatus.inProgress => strings.journalCalendarCurrent,
    };
    Widget dayCell(BuildContext context, DateTime date, DateTime focused) {
      final day = JournalDay.fromDate(date);
      final summary = provider.summary(day);
      final status = journalDayStatus(summary, today);
      final color = switch (status) {
        JournalDayStatus.success => green,
        JournalDayStatus.failure => red,
        _ => Colors.transparent,
      };
      final isToday = day == today;
      final selected = day == widget.initial;
      final description = summary.tasks.isEmpty
          ? '${MaterialLocalizations.of(context).formatFullDate(date)} : ${label(status)}'
          : strings.journalCalendarDay(
              MaterialLocalizations.of(context).formatFullDate(date),
              label(status),
              summary.completed.length,
              summary.tasks.length,
            );
      return Semantics(
        key: ValueKey('journal-calendar-${day.key}'),
        label: description,
        selected: selected,
        excludeSemantics: true,
        child: Tooltip(
          message: description,
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isToday ? theme.colorScheme.primary : Colors.transparent,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? theme.colorScheme.surfaceContainerHighest
                    : null,
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                '${date.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isToday || selected ? FontWeight.w700 : null,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget legend(String text, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.bodySmall),
      ],
    );
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  strings.journalCalendarTitle,
                  style: theme.textTheme.titleLarge,
                ),
                TableCalendar<void>(
                  locale: strings.localeName,
                  firstDay: first,
                  lastDay: last,
                  focusedDay: _focused,
                  currentDay: today.date,
                  startingDayOfWeek: StartingDayOfWeek.monday,
                  selectedDayPredicate: (date) =>
                      JournalDay.fromDate(date) == widget.initial,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                  daysOfWeekHeight: 28,
                  rowHeight: 46,
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: theme.textTheme.labelMedium!,
                    weekendStyle: theme.textTheme.labelMedium!,
                  ),
                  calendarStyle: const CalendarStyle(outsideDaysVisible: false),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: dayCell,
                    todayBuilder: dayCell,
                    selectedBuilder: dayCell,
                    outsideBuilder: dayCell,
                  ),
                  onPageChanged: (focused) =>
                      setState(() => _focused = focused),
                  onDaySelected: (selected, _) =>
                      Navigator.pop(context, JournalDay.fromDate(selected)),
                  onHeaderTapped: (_) async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _focused,
                      firstDate: first,
                      lastDate: last,
                      initialDatePickerMode: DatePickerMode.year,
                    );
                    if (date != null && mounted)
                      setState(() => _focused = date);
                  },
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    legend(strings.journalToday, theme.colorScheme.primary),
                    legend(strings.journalCalendarSuccess, green),
                    legend(strings.journalCalendarFailure, red),
                    Text(
                      strings.journalCalendarEmpty,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  strings.journalCalendarHelp,
                  style: theme.textTheme.bodySmall,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
