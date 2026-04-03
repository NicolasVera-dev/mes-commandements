import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mes_commandements/app/command_card_layout_service.dart';
import 'package:mes_commandements/features/auth/domain/entities/auth_user.dart';
import 'package:mes_commandements/features/auth/domain/repositories/auth_repository.dart';
import 'package:mes_commandements/features/auth/presentation/state/auth_provider.dart';
import 'package:mes_commandements/features/commands/domain/entities/auto_reset_report.dart';
import 'package:mes_commandements/features/commands/domain/entities/command.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_event.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_events_period.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_position_update.dart';
import 'package:mes_commandements/features/commands/domain/repositories/command_event_repository.dart';
import 'package:mes_commandements/features/commands/domain/repositories/command_repository.dart';
import 'package:mes_commandements/features/commands/presentation/pages/command_detail_page.dart';
import 'package:mes_commandements/features/commands/presentation/pages/edit_command_page.dart';
import 'package:mes_commandements/features/commands/presentation/state/command_provider.dart';
import 'package:mes_commandements/features/commands/presentation/widgets/command_card.dart';
import 'package:mes_commandements/features/commands/presentation/widgets/command_reset_lifecycle_listener.dart';
import 'package:mes_commandements/features/commands/presentation/widgets/create_command_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

late final CommandCardLayoutService _testCardLayout;

class _FakeCommandRepository implements CommandRepository {
  final StreamController<List<Command>> controller =
      StreamController<List<Command>>.broadcast();
  AutoResetReport autoResetReport = const AutoResetReport.empty();
  Object? addError;
  Object? updateError;
  int incrementCalls = 0;
  int addCalls = 0;
  int updateCalls = 0;

  void emit(List<Command> commands) => controller.add(commands);

  @override
  Stream<List<Command>> watchAll() => controller.stream;

  @override
  Future<AutoResetReport> applyPendingAutoResets(DateTime now) async =>
      autoResetReport;

  @override
  Future<void> add(Command command) async {
    addCalls++;
    if (addError != null) throw addError!;
  }

  @override
  Future<void> delete(String commandId) async {}

  @override
  Future<void> incrementProgress(String commandId) async {
    incrementCalls++;
  }

  @override
  Future<void> resetProgress(String commandId) async {}

  @override
  Future<void> update(Command command) async {
    updateCalls++;
    if (updateError != null) throw updateError!;
  }

  @override
  Future<void> updatePositions(List<CommandPositionUpdate> updates) async {}

  void dispose() {
    controller.close();
  }
}

class _FakeCommandEventRepository implements CommandEventRepository {
  final StreamController<List<CommandEvent>> controller =
      StreamController<List<CommandEvent>>.broadcast();
  Future<DateTime?> Function(String commandId)? firstEventResolver;

  void emit(List<CommandEvent> events) => controller.add(events);
  void emitError(Object error) => controller.addError(error);

  @override
  void addEventFireAndForget({
    required String commandId,
    required CommandEvent event,
  }) {}

  @override
  Future<void> deleteAllEvents(String commandId) async {}

  @override
  Future<DateTime?> firstEventAtUtc(String commandId) async {
    return firstEventResolver?.call(commandId);
  }

  @override
  Stream<List<CommandEvent>> watchEvents(
    String commandId, {
    CommandEventsPeriod? period,
  }) {
    return controller.stream;
  }

  void dispose() {
    controller.close();
  }
}

class _FakeAuthRepository implements AuthRepository {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();
  final AuthUser? _initialUser;

  _FakeAuthRepository(this._initialUser);

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _initialUser;
    yield* _controller.stream;
  }

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => const AuthUser(uid: 'u1', email: 'test@example.com');

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async => const AuthUser(uid: 'u1', email: 'test@example.com');

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  void dispose() {
    _controller.close();
  }
}

Command _command({
  required String id,
  required int progress,
  int target = 3,
  Frequency frequency = Frequency.daily,
  DateTime? createdAt,
}) {
  return Command(
    id: id,
    title: 'Commandement $id',
    target: target,
    progress: progress,
    frequency: frequency,
    createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
  );
}

Widget _wrap({
  required CommandProvider provider,
  CommandEventRepository? eventRepository,
  AuthProvider? authProvider,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CommandProvider>.value(value: provider),
      ChangeNotifierProvider<CommandCardLayoutService>.value(
        value: _testCardLayout,
      ),
      if (eventRepository != null)
        Provider<CommandEventRepository>.value(value: eventRepository),
      if (authProvider != null)
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(<String, Object>{});

  setUpAll(() async {
    final prefs = await SharedPreferences.getInstance();
    _testCardLayout = CommandCardLayoutService(prefs: prefs);
  });

  group('CommandCard', () {
    testWidgets('tap incrémente et menu 3 points affiche les options',
        (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final command = _command(id: 'c1', progress: 0);
      repo.emit([command]);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: CommandCard(command: command),
        ),
      );
      await tester.tap(find.text('Commandement c1'));
      await tester.pump();
      expect(repo.incrementCalls, 1);

      await tester.tap(find.byTooltip('Actions'));
      await tester.pumpAndSettle();
      expect(find.text('Voir le détail'), findsOneWidget);
      expect(find.text('Modifier'), findsOneWidget);
      expect(find.text('Supprimer'), findsOneWidget);

      provider.dispose();
      repo.dispose();
    });

    testWidgets('affiche icône completed uniquement si target atteinte',
        (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: Column(
            children: [
              CommandCard(command: _command(id: 'a', progress: 3, target: 3)),
              CommandCard(command: _command(id: 'b', progress: 1, target: 3)),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      provider.dispose();
      repo.dispose();
    });
  });

  group('Page détail', () {
    testWidgets('état vide si aucun historique et fallback createdAt absent',
        (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository()
        ..firstEventResolver = (_) async => null;
      repo.emit([
        Command(
          id: 'c1',
          title: 'Cmd',
          target: 3,
          progress: 0,
          frequency: Frequency.weekly,
          createdAt: null,
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        find.textContaining('Aucun historique pour ce commandement'),
        findsOneWidget,
      );

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });

    testWidgets('navigation précédent/suivant en yearly met à jour la période',
        (tester) async {
      final nowYear = DateTime.now().toUtc().year;
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository()
        ..firstEventResolver = (_) async => DateTime.utc(nowYear, 1, 1);
      repo.emit([
        _command(
          id: 'c2',
          progress: 0,
          frequency: Frequency.yearly,
          createdAt: DateTime.utc(nowYear, 1, 1),
        ),
      ]);
      eventsRepo.emit(const []);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c2'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('$nowYear'), findsWidgets);
      await tester.tap(find.byTooltip('Période précédente'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('${nowYear - 1}'), findsWidgets);

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });

    testWidgets('accessibilité: navigation lisible via tooltips',
        (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository()
        ..firstEventResolver = (_) async => DateTime.utc(2026, 1, 1);
      final now = DateTime.now().toUtc();
      repo.emit([
        _command(
          id: 'c3',
          progress: 1,
          frequency: Frequency.yearly,
          createdAt: DateTime.utc(now.year, 1, 1),
        ),
      ]);
      eventsRepo.emit(const []);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c3'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byTooltip('Période précédente'), findsOneWidget);
      expect(find.byTooltip('Période suivante'), findsOneWidget);

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });

    testWidgets('état loading historique affiche skeleton', (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository();
      final completer = Completer<DateTime?>();
      eventsRepo.firstEventResolver = (_) => completer.future;
      repo.emit([
        Command(
          id: 'c4',
          title: 'Cmd',
          target: 2,
          progress: 0,
          frequency: Frequency.daily,
          createdAt: null,
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c4'),
        ),
      );
      await tester.pump();
      expect(find.byType(AnimatedBuilder), findsWidgets);

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });

    testWidgets('état error historique affiche message', (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository()
        ..firstEventResolver = (_) async => throw StateError('boom');
      repo.emit([
        Command(
          id: 'c5',
          title: 'Cmd',
          target: 2,
          progress: 0,
          frequency: Frequency.daily,
          createdAt: null,
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c5'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Impossible de charger l’historique.'), findsOneWidget);

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });
  });

  group('Reset automatique lifecycle', () {
    testWidgets('snackbar affichée uniquement si reset eu lieu', (tester) async {
      final repo = _FakeCommandRepository()
        ..autoResetReport = const AutoResetReport(
          total: 1,
          byFrequency: {Frequency.daily: 1},
        );
      final provider = CommandProvider(repository: repo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: const CommandResetLifecycleListener(child: Text('Child')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('remis à zéro'), findsOneWidget);

      provider.dispose();
      repo.dispose();
    });

    testWidgets('pas de snackbar si aucun reset', (tester) async {
      final repo = _FakeCommandRepository()
        ..autoResetReport = const AutoResetReport.empty();
      final provider = CommandProvider(repository: repo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: const CommandResetLifecycleListener(child: Text('Child')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('remis à zéro'), findsNothing);

      provider.dispose();
      repo.dispose();
    });
  });

  group('Formulaire création/édition', () {
    testWidgets('création: validation puis soumission', (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreateCommandSheet(
                context: context,
                initialFrequency: Frequency.daily,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Enregistrer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Veuillez entrer un titre'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test');
      await tester.enterText(fields.at(1), '3');
      await tester.scrollUntilVisible(
        find.text('Enregistrer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(repo.addCalls, 1);

      provider.dispose();
      repo.dispose();
    });

    testWidgets('édition: tap hors champ retire le focus', (tester) async {
      final cmd = _command(id: 'edit', progress: 1, target: 3);
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      repo.emit([cmd]);
      final fakeAuthRepo =
          _FakeAuthRepository(const AuthUser(uid: 'u1', email: 'a@b.c'));
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          authProvider: authProvider,
          child: const EditCommandPage(commandId: 'edit'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.tap(find.text('Modifier le commandement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final editable = find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(editable).focusNode.hasFocus, isFalse);

      authProvider.dispose();
      fakeAuthRepo.dispose();
      provider.dispose();
      repo.dispose();
    });

    testWidgets('création: tap hors champ retire le focus', (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreateCommandSheet(
                context: context,
                initialFrequency: Frequency.daily,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).first);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);

      await tester.tap(find.text('Créer un commandement'));
      await tester.pump();
      final editableCreate = find.descendant(
        of: find.byType(TextFormField).first,
        matching: find.byType(EditableText),
      );
      expect(
        tester.widget<EditableText>(editableCreate).focusNode.hasFocus,
        isFalse,
      );

      provider.dispose();
      repo.dispose();
    });

    testWidgets('création: tap hors champ puis Enregistrer soumet toujours',
        (tester) async {
      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          child: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreateCommandSheet(
                context: context,
                initialFrequency: Frequency.daily,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Test');
      await tester.enterText(fields.at(1), '3');
      await tester.tap(find.text('Créer un commandement'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Enregistrer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(repo.addCalls, 1);

      provider.dispose();
      repo.dispose();
    });

    testWidgets('édition: soumission + gestion erreur repository',
        (tester) async {
      final cmd = _command(id: 'edit', progress: 1, target: 3);
      final repo = _FakeCommandRepository()..updateError = StateError('fail');
      final provider = CommandProvider(repository: repo)..addListener(() {});
      repo.emit([cmd]);
      final fakeAuthRepo =
          _FakeAuthRepository(const AuthUser(uid: 'u1', email: 'a@b.c'));
      final authProvider = AuthProvider(repository: fakeAuthRepo);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          authProvider: authProvider,
          child: const EditCommandPage(commandId: 'edit'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), '3');
      await tester.enterText(fields.at(2), '2');
      await tester.scrollUntilVisible(
        find.text('Enregistrer'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(repo.updateCalls, 1);
      expect(provider.syncErrorMessage, isNotNull);

      authProvider.dispose();
      fakeAuthRepo.dispose();
      provider.dispose();
      repo.dispose();
    });
  });
}
