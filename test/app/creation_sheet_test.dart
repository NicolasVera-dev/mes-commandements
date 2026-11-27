import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rituel/app/command_card_layout_service.dart';
import 'package:rituel/app/app_theme.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/commands/data/repositories/firestore_command_repository.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/presentation/state/command_provider.dart';
import 'package:rituel/features/commands/presentation/widgets/create_command_sheet.dart';
import 'package:rituel/features/resistances/data/repositories/firestore_resistance_repository.dart';
import 'package:rituel/features/resistances/domain/usecases/record_resistance_relapse_usecase.dart';
import 'package:rituel/features/resistances/presentation/state/resistance_provider.dart';
import 'package:rituel/features/resistances/presentation/widgets/create_resistance_sheet.dart';
import 'package:rituel/features/resistances/presentation/widgets/resistance_card.dart';
import 'package:rituel/features/resistances/domain/entities/resistance.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';
import 'package:rituel/features/journal/presentation/state/journal_provider.dart';
import 'package:rituel/features/journal/presentation/widgets/journal_task_sheet.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'u', email: 'u@example.com'));
}

void main() {
  testWidgets(
    'all three creation sheets share bounds, keep their handle safe and do not open the keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = FakeFirebaseFirestore();
      final auth = _Auth();
      final commands = CommandProvider(
        repository: FirestoreCommandRepository(
          authRepository: auth,
          firestore: db,
        ),
      );
      final repo = FirestoreResistanceRepository(
        authRepository: auth,
        firestore: db,
      );
      final resistances = ResistanceProvider(
        repository: repo,
        recordRelapseUseCase: RecordResistanceRelapseUseCase(repo),
      );
      final journal = JournalProvider(
        repository: FirestoreJournalRepository(firestore: db),
        userIds: Stream.value('u'),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: commands),
            ChangeNotifierProvider.value(value: resistances),
            ChangeNotifierProvider.value(value: journal),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.only(top: 44),
                viewPadding: const EdgeInsets.only(top: 44),
              ),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () =>
                          showCreateResistanceSheet(context: context),
                      child: const Text('resistance'),
                    ),
                    TextButton(
                      onPressed: () => showCreateCommandSheet(
                        context: context,
                        initialFrequency: Frequency.daily,
                      ),
                      child: const Text('command'),
                    ),
                    TextButton(
                      onPressed: () =>
                          showJournalTaskSheet(context, day: journal.today),
                      child: const Text('task'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Rect? reference;
      for (final label in ['resistance', 'command', 'task']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, false);
        final sheet = find.byType(BottomSheet);
        expect(tester.widget<BottomSheet>(sheet).showDragHandle, true);
        final rect = tester.getRect(sheet);
        expect(rect.top, greaterThanOrEqualTo(44));
        reference ??= rect;
        expect(rect, reference);
        if (label == 'task') {
          expect(find.text('Prévue pour aujourd’hui'), findsOneWidget);
          final reportable = tester
              .widgetList<SwitchListTile>(find.byType(SwitchListTile))
              .last;
          expect(reportable.value, true);
        }
        Navigator.of(tester.element(find.byType(Form).first)).pop();
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      commands.dispose();
      resistances.dispose();
      journal.dispose();
    },
  );
  testWidgets(
    'record trophy survives best synchronization and disappears on relapse',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final layout = CommandCardLayoutService(
        prefs: await SharedPreferences.getInstance(),
      );
      final db = FakeFirebaseFirestore();
      final auth = _Auth();
      final repo = FirestoreResistanceRepository(
        authRepository: auth,
        firestore: db,
      );
      final provider = ResistanceProvider(
        repository: repo,
        recordRelapseUseCase: RecordResistanceRelapseUseCase(repo),
      );
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      await repo.add(
        Resistance(
          id: 'r',
          title: 'Tabac',
          createdAtUtc: today.subtract(const Duration(days: 6)),
          bestStreakDays: 5,
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: layout),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme(),
            home: Scaffold(
              body: Consumer<ResistanceProvider>(
                builder: (context, state, _) {
                  final r = state.getById('r');
                  return r == null
                      ? const SizedBox.shrink()
                      : ResistanceCard(resistance: r);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('🏆'), findsOneWidget);
      expect(provider.getById('r')!.bestStreakDays, 6);
      expect(provider.getById('r')!.bestStreakBeforeRun, 5);
      await repo.recordRelapse(
        resistanceId: 'r',
        relapsedAtUtc: now,
        previousStreakDays: 6,
        newBestStreakDays: 6,
      );
      await tester.pumpAndSettle();
      expect(find.text('🏆'), findsNothing);
      expect(provider.getById('r')!.bestStreakBeforeRun, 6);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      layout.dispose();
    },
  );
}
