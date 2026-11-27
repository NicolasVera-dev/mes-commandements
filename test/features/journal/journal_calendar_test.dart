import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rituel/app/app_theme.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/journal/domain/entities/journal_day.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/journal/domain/services/journal_day_summary.dart';
import 'package:rituel/features/journal/domain/services/journal_day_status.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';
import 'package:rituel/features/journal/presentation/state/journal_provider.dart';
import 'package:rituel/features/journal/presentation/widgets/journal_calendar_dialog.dart';

void main() {
  final today = JournalDay.parse('2026-11-27');
  JournalTask task(String id, JournalDay day) => JournalTask(
    id: id,
    title: id,
    plans: [JournalPlan(start: day, carryForward: false)],
  );
  test('calendar separates empty days, future plans, current progress, success and closed failures', () {
    JournalDayStatus status(List<JournalTask> tasks, JournalDay day) =>
        journalDayStatus(JournalDaySummary(tasks: tasks, day: day), today);
    expect(status([], today), JournalDayStatus.empty);
    expect(status([task('a', today)], today), JournalDayStatus.inProgress);
    expect(
      status([task('a', today.add(1))], today.add(1)),
      JournalDayStatus.planned,
    );
    expect(
      status([task('a', today.add(-1))], today.add(-1)),
      JournalDayStatus.failure,
    );
    expect(
      status([task('a', today).complete(today, done: true)], today),
      JournalDayStatus.success,
    );
    final tasks = [
      for (var i = 0; i < 200; i++)
        task('$i', today.add(-1)).complete(today.add(-1), done: true),
      task('last', today.add(-1)),
    ];
    expect(JournalDaySummary(tasks: tasks, day: today.add(-1)).score, 100);
    expect(status(tasks, today.add(-1)), JournalDayStatus.failure);
  });
  for (final config in [
    (locale: 'fr', width: 375.0, height: 812.0, scale: 1.0),
    (locale: 'en', width: 375.0, height: 812.0, scale: 1.0),
    (locale: 'fr', width: 320.0, height: 568.0, scale: 1.5),
  ]) {
    final locale = config.locale;
    testWidgets(
      '$locale: calendar shows historical statuses, retains today outline and selects a day',
      (tester) async {
        tester.view.physicalSize = Size(config.width, config.height);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FirestoreJournalRepository(
          firestore: FakeFirebaseFirestore(),
        );
        await repo.saveTask(
          'u',
          task('success', today.add(-2)).complete(today.add(-2), done: true),
        );
        await repo.saveTask('u', task('failure', today.add(-1)));
        await repo.saveTask('u', task('current', today));
        final provider = JournalProvider(
          repository: repo,
          userIds: Stream.value('u'),
          clock: () => today.date,
        );
        JournalDay? selected;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: provider,
            child: MaterialApp(
              theme: locale == 'en'
                  ? AppTheme.darkTheme()
                  : AppTheme.lightTheme(),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(config.scale)),
                child: child!,
              ),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      selected = await showJournalCalendar(context, today);
                    },
                    child: const Text('calendar'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('calendar'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey('journal-calendar-${today.key}')),
          findsOneWidget,
        );
        final success = find.byKey(
          ValueKey('journal-calendar-${today.add(-2).key}'),
        );
        final failure = find.byKey(
          ValueKey('journal-calendar-${today.add(-1).key}'),
        );
        expect(success, findsOneWidget);
        expect(failure, findsOneWidget);
        final semantic =
            (locale == 'en' ? AppTheme.darkTheme() : AppTheme.lightTheme())
                .extension<AppSemanticColors>()!;
        Color border(Finder finder) => tester
            .widgetList<Container>(
              find.descendant(of: finder, matching: find.byType(Container)),
            )
            .map((w) => w.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.border)
            .whereType<Border>()
            .last
            .top
            .color;
        expect(border(success), semantic.successIndicator);
        expect(border(failure), semantic.failedIndicator);
        await tester.ensureVisible(success);
        await tester.tap(success);
        await tester.pumpAndSettle();
        expect(selected, today.add(-2));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        provider.dispose();
      },
    );
  }
}
