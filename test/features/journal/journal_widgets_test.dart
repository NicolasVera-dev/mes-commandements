import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rituel/app/app_theme.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';
import 'package:rituel/features/journal/domain/entities/journal_day.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/journal/presentation/pages/journal_page.dart';
import 'package:rituel/features/journal/presentation/state/journal_provider.dart';
import 'package:rituel/features/journal/presentation/widgets/journal_task_card.dart';

Future<void> mount(
  WidgetTester tester,
  JournalProvider provider,
  String language, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(
        theme: dark ? AppTheme.darkTheme() : AppTheme.lightTheme(),
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const JournalPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'one-day task is created without a keyboard and stays missed in its original day',
    (tester) async {
      final repo = FirestoreJournalRepository(
        firestore: FakeFirebaseFirestore(),
      );
      var now = DateTime(2026, 11, 25);
      final provider = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => now,
      );
      await mount(tester, provider, 'fr');
      await tester.tap(find.text('Nouvelle tâche'));
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, false);
      expect(find.text('Prévue pour aujourd’hui'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Envoyer le devis');
      await tester.ensureVisible(find.text('Reportable'));
      await tester.tap(find.text('Reportable'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Enregistrer'));
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(provider.summary(provider.today).tasks.single.carryForward, false);
      now = DateTime(2026, 11, 26);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Envoyer le devis'), findsNothing);
      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      expect(find.text('Envoyer le devis'), findsOneWidget);
      expect(find.text('Non accomplie · non reportable'), findsOneWidget);
      expect(find.text('0 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );
  testWidgets('task drag proxy is transparent and reordering persists', (
    tester,
  ) async {
    final repo = FirestoreJournalRepository(firestore: FakeFirebaseFirestore());
    final today = JournalDay.parse('2026-11-25');
    for (var i = 0; i < 2; i++) {
      await repo.saveTask(
        'a',
        JournalTask(
          id: '$i',
          title: 'Tâche $i',
          order: i.toDouble(),
          plans: [JournalPlan(start: today)],
        ),
      );
    }
    final provider = JournalProvider(
      repository: repo,
      userIds: Stream.value('a'),
      clock: () => today.date,
    );
    await mount(tester, provider, 'fr');
    final first = tester.getCenter(find.text('Tâche 0'));
    final gesture = await tester.startGesture(first);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(first + const Offset(0, 15));
    await tester.pump(const Duration(milliseconds: 350));
    final proxy = tester.widget<Material>(
      find.byKey(const ValueKey('journal_drag_proxy')),
    );
    expect(proxy.type, MaterialType.transparency);
    await gesture.up();
    await tester.pumpAndSettle();
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 1);
    await tester.pumpAndSettle();
    expect(provider.summary(today).pending.first.id, '1');
    expect(
      (await repo.watchTasks('a').first).firstWhere((t) => t.id == '1').order,
      0,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });

  for (final language in ['fr', 'en']) {
    testWidgets(
      '$language: add, accomplish, delete/undo and save a daily review on a small screen',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = FirestoreJournalRepository(
          firestore: FakeFirebaseFirestore(),
        );
        final provider = JournalProvider(
          repository: repo,
          userIds: Stream.value('a'),
          clock: () => DateTime(2026, 11, 25),
        );
        final strings = lookupAppLocalizations(Locale(language));
        await mount(tester, provider, language, dark: language == 'en');
        await tester.tap(find.text(strings.journalAddTask));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.journalSave));
        await tester.pumpAndSettle();
        expect(find.text(strings.journalTaskRequired), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), 'Envoyer le devis');
        await tester.tap(find.text(strings.journalSave));
        await tester.pumpAndSettle();
        expect(provider.summary(provider.today).pending, hasLength(1));
        expect(find.text('Envoyer le devis'), findsOneWidget);
        expect(find.text(strings.journalCompletedCount(0, 1)), findsOneWidget);
        expect(find.text('0 %'), findsOneWidget);
        await tester.tap(find.byType(Checkbox));
        await tester.pumpAndSettle();
        expect(find.text('100 %'), findsOneWidget);
        expect(find.text(strings.journalCelebrate), findsOneWidget);
        expect(find.text(strings.journalAllDoneFeedback), findsOneWidget);
        await tester.tap(find.byType(PopupMenuButton<JournalTaskAction>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.journalDeleteTask));
        await tester.pumpAndSettle();
        expect(provider.summary(provider.today).tasks, isEmpty);
        await tester.tap(find.text(strings.journalUndo));
        await tester.pumpAndSettle();
        expect(provider.summary(provider.today).score, 100);
        await tester.tap(find.text(strings.journalReviewAction));
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.journalMoodSatisfied));
        await tester.enterText(
          find.byType(TextField),
          'Fier du travail accompli',
        );
        await tester.ensureVisible(find.text(strings.journalSave));
        await tester.tap(find.text(strings.journalSave));
        await tester.pumpAndSettle();
        expect(
          provider.reflection(provider.today)?.note,
          'Fier du travail accompli',
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        provider.dispose();
      },
    );
  }

  testWidgets(
    'deletion banner closes automatically after five seconds and can be closed manually',
    (tester) async {
      final repo = FirestoreJournalRepository(
        firestore: FakeFirebaseFirestore(),
      );
      final today = JournalDay.parse('2026-11-25');
      for (final id in ['a', 'b']) {
        await repo.saveTask(
          'a',
          JournalTask(
            id: id,
            title: 'Tâche $id',
            plans: [JournalPlan(start: today)],
          ),
        );
      }
      final provider = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => today.date,
      );
      await mount(tester, provider, 'fr');
      Future<void> removeFirst() async {
        await tester.tap(find.byType(PopupMenuButton<JournalTaskAction>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Supprimer la tâche'));
        await tester.pumpAndSettle();
      }

      await removeFirst();
      expect(find.text('Tâche supprimée du planning.'), findsOneWidget);
      expect(find.text('Annuler'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      expect(find.byType(SnackBar), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(provider.summary(today).tasks, hasLength(1));
      await removeFirst();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(provider.summary(today).tasks, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets(
    'past is read-only, future cannot be checked, overdue carries on resume',
    (tester) async {
      final repo = FirestoreJournalRepository(
        firestore: FakeFirebaseFirestore(),
      );
      var now = DateTime(2026, 11, 25, 23, 59);
      final today = JournalDay.fromDate(now);
      await repo.saveTask(
        'a',
        JournalTask(
          id: 'task',
          title: 'Devis',
          plans: [JournalPlan(start: today.add(-1))],
        ),
      );
      final provider = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => now,
      );
      await mount(tester, provider, 'fr');
      expect(find.text('1 jour de retard'), findsOneWidget);
      now = DateTime(2026, 11, 26);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('2 jours de retard'), findsOneWidget);
      await tester.tap(find.byTooltip('Jour précédent'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(find.byType(PopupMenuButton<JournalTaskAction>), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      await tester.tap(find.text('Aujourd’hui'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Jour suivant'));
      await tester.pumpAndSettle();
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(find.text('Journée en préparation'), findsOneWidget);
      expect(find.text('Mon bilan'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
    },
  );

  testWidgets('large text and narrow layout keep the journal actions usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = FirestoreJournalRepository(firestore: FakeFirebaseFirestore());
    final today = JournalDay.parse('2026-11-25');
    await repo.saveTask(
      'a',
      JournalTask(
        id: 'task',
        title: 'Une longue tâche importante pour préparer ma présentation de demain',
        priority: true,
        plans: [JournalPlan(start: today.add(-4))],
      ),
    );
    final provider = JournalProvider(
      repository: repo,
      userIds: Stream.value('a'),
      clock: () => today.date,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.5)),
            child: child!,
          ),
          home: const JournalPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
  });
}
