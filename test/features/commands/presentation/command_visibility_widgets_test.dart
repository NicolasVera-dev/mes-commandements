import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rituel/app/app_theme.dart';
import 'package:rituel/app/command_card_layout_service.dart';
import 'package:rituel/app/localization/localization.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/auth/presentation/state/auth_provider.dart';
import 'package:rituel/features/commands/data/repositories/firestore_command_repository.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/repositories/command_event_repository.dart';
import 'package:rituel/features/commands/presentation/pages/home_page.dart';
import 'package:rituel/features/commands/presentation/state/command_provider.dart';
import 'package:rituel/features/commands/presentation/widgets/command_card.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'u', email: 'u@example.com'));
}

class _Events extends Fake implements CommandEventRepository {
  @override
  Stream<List<CommandEvent>> watchEventsFrom(
    String commandId, {
    required DateTime startUtcInclusive,
  }) => Stream.value([]);
}

Command _command(String id) => Command(
  id: id,
  title: id,
  target: 7,
  progress: 2,
  frequency: Frequency.daily,
  createdAt: DateTime.now().toUtc(),
);

void main() {
  for (final locale in ['fr', 'en']) {
    testWidgets(
      '$locale: hide from card, find in folded section, restore paused and filter',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final layout = CommandCardLayoutService(
          prefs: await SharedPreferences.getInstance(),
        );
        final db = FakeFirebaseFirestore();
        final authRepo = _Auth();
        final auth = AuthProvider(repository: authRepo);
        final repository = FirestoreCommandRepository(
          authRepository: authRepo,
          firestore: db,
        );
        final provider = CommandProvider(repository: repository);
        await repository.add(_command('Marcher 7k pas'));
        await repository.add(_command('Marcher 8k pas'));
        final strings = lookupAppLocalizations(Locale(locale));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: provider),
              ChangeNotifierProvider.value(value: auth),
              ChangeNotifierProvider.value(value: layout),
              Provider<CommandEventRepository>.value(value: _Events()),
            ],
            child: MaterialApp(
              theme: locale == 'fr'
                  ? AppTheme.lightTheme()
                  : AppTheme.darkTheme(),
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const HomePage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byWidgetPredicate(
          (w) => w is CommandCard && w.command.title == 'Marcher 7k pas',
        );
        await tester.tap(
          find.descendant(
            of: card,
            matching: find.byIcon(Icons.more_vert_rounded),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.hideCommandAction));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, strings.hideCommandAction),
        );
        await tester.pumpAndSettle();
        expect(
          provider.commands.where((c) => c.isHidden).single.title,
          'Marcher 7k pas',
        );
        expect(find.text('Marcher 7k pas'), findsNothing);
        expect(find.text(strings.hiddenCommandsTitle(1)), findsOneWidget);
        await tester.ensureVisible(find.text(strings.hiddenCommandsTitle(1)));
        await tester.tap(find.text(strings.hiddenCommandsTitle(1)));
        await tester.pumpAndSettle();
        expect(find.text('Marcher 7k pas'), findsOneWidget);
        final hiddenRow = find.ancestor(
          of: find.text('Marcher 7k pas'),
          matching: find.byType(ListTile),
        );
        await tester.ensureVisible(hiddenRow);
        await tester.tap(
          find.descendant(
            of: hiddenRow,
            matching: find.byTooltip(strings.actionsDuCommandement),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(strings.showCommandAction));
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FilledButton, strings.showCommandAction),
        );
        await tester.pumpAndSettle();
        expect(provider.commands.where((c) => c.isHidden), isEmpty);
        expect(
          provider.commands
              .firstWhere((c) => c.title == 'Marcher 7k pas')
              .isPausedAt(DateTime.now()),
          true,
        );
        await tester.tap(find.byTooltip(strings.filtres));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilterChip, strings.enPause));
        await tester.scrollUntilVisible(
          find.text(strings.valider),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text(strings.valider));
        await tester.pumpAndSettle();
        expect(find.text('Marcher 8k pas'), findsNothing);
        expect(find.text('Marcher 7k pas'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        provider.dispose();
        auth.dispose();
        layout.dispose();
      },
    );
  }

  testWidgets(
    'all-hidden list still exposes its collapsed section and permanent deletion asks confirmation',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final layout = CommandCardLayoutService(
        prefs: await SharedPreferences.getInstance(),
      );
      final db = FakeFirebaseFirestore();
      final authRepo = _Auth();
      final auth = AuthProvider(repository: authRepo);
      final repository = FirestoreCommandRepository(
        authRepository: authRepo,
        firestore: db,
      );
      final provider = CommandProvider(repository: repository);
      await repository.add(_command('Ancien objectif').hideAt(DateTime.now()));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: auth),
            ChangeNotifierProvider.value(value: layout),
            Provider<CommandEventRepository>.value(value: _Events()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            home: const HomePage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Commandements masqués (1)'), findsOneWidget);
      expect(find.text('Ancien objectif'), findsNothing);
      await tester.tap(find.text('Commandements masqués (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Actions du commandement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(provider.commands, hasLength(1));
      await tester.tap(find.byTooltip('Actions du commandement'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Supprimer'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Supprimer'));
      await tester.pumpAndSettle();
      expect(provider.commands, isEmpty);
      expect(find.text('Commandements masqués (1)'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      auth.dispose();
      layout.dispose();
    },
  );
}
