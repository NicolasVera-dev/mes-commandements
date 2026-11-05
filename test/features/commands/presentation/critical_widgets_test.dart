import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/app/command_card_layout_service.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/auth/presentation/state/auth_provider.dart';
import 'package:rituel/features/commands/domain/entities/auto_reset_report.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/entities/command_events_period.dart';
import 'package:rituel/features/commands/domain/entities/command_position_update.dart';
import 'package:rituel/features/commands/domain/entities/cycle_note.dart';
import 'package:rituel/features/commands/domain/repositories/command_event_repository.dart';
import 'package:rituel/features/commands/domain/repositories/command_repository.dart';
import 'package:rituel/features/commands/domain/repositories/cycle_note_repository.dart';
import 'package:rituel/features/commands/domain/usecases/save_cycle_note_usecase.dart';
import 'package:rituel/features/commands/presentation/state/cycle_note_provider.dart';
import 'package:rituel/features/commands/presentation/pages/command_detail_page.dart';
import 'package:rituel/features/commands/presentation/pages/edit_command_page.dart';
import 'package:rituel/features/commands/presentation/state/command_provider.dart';
import 'package:rituel/features/commands/presentation/widgets/command_card.dart';
import 'package:rituel/features/commands/presentation/widgets/command_reset_lifecycle_listener.dart';
import 'package:rituel/features/commands/presentation/widgets/create_command_sheet.dart';
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
  Future<void> completePastCycle({
    required String commandId,
    required String cycleKey,
  }) async {}

  @override
  Future<void> uncompletePastCycle({
    required String commandId,
    required String cycleKey,
  }) async {}

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

class _FakeCycleNoteRepository implements CycleNoteRepository {
  @override
  Stream<Map<String, CycleNote>> watchNotes(
    String commandId, {
    required Set<String> cycleKeys,
  }) => Stream<Map<String, CycleNote>>.value(<String, CycleNote>{});

  @override
  Future<void> deleteAllNotes(String commandId) async {}

  @override
  Future<void> deleteNote({
    required String commandId,
    required String cycleKey,
  }) async {}

  @override
  Future<void> saveNote(CycleNote note) async {}
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

  @override
  Stream<List<CommandEvent>> watchEventsFrom(
    String commandId, {
    required DateTime startUtcInclusive,
  }) async* {
    yield <CommandEvent>[];
    yield* controller.stream;
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

CommandEvent _event({
  required String cycleKey,
  required CommandEventType type,
  DateTime? actionAtUtc,
  int progressAfterAction = 1,
  int targetAtAction = 1,
}) {
  return CommandEvent(
    type: type,
    actionAtUtc: actionAtUtc ?? DateTime.utc(2026, 3, 1, 12),
    progressAfterAction: progressAfterAction,
    targetAtAction: targetAtAction,
    cycleKey: cycleKey,
  );
}

Widget _wrap({
  required CommandProvider provider,
  CommandEventRepository? eventRepository,
  AuthProvider? authProvider,
  required Widget child,
}) {
  final cycleNoteRepo = _FakeCycleNoteRepository();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<CommandProvider>.value(value: provider),
      ChangeNotifierProvider<CommandCardLayoutService>.value(
        value: _testCardLayout,
      ),
      Provider<CommandEventRepository>.value(
        value: eventRepository ?? _FakeCommandEventRepository(),
      ),
      Provider<CycleNoteRepository>.value(value: cycleNoteRepo),
      ChangeNotifierProvider(
        create: (_) => CycleNoteProvider(
          repository: cycleNoteRepo,
          saveUseCase: SaveCycleNoteUseCase(cycleNoteRepo),
        ),
      ),
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
    testWidgets('tap incrémente et menu 3 points affiche les options', (
      tester,
    ) async {
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

    testWidgets('affiche icône completed uniquement si target atteinte', (
      tester,
    ) async {
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
    testWidgets('streak reste affichée quand historique de succès présent', (
      tester,
    ) async {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      final d1 = todayStart.subtract(const Duration(days: 1));
      final d2 = todayStart.subtract(const Duration(days: 2));
      final d3 = todayStart.subtract(const Duration(days: 3));
      final k1 =
          '${d1.year}-${d1.month.toString().padLeft(2, '0')}-${d1.day.toString().padLeft(2, '0')}';
      final k2 =
          '${d2.year}-${d2.month.toString().padLeft(2, '0')}-${d2.day.toString().padLeft(2, '0')}';
      final k3 =
          '${d3.year}-${d3.month.toString().padLeft(2, '0')}-${d3.day.toString().padLeft(2, '0')}';

      final repo = _FakeCommandRepository();
      final provider = CommandProvider(repository: repo);
      final eventsRepo = _FakeCommandEventRepository()
        ..firstEventResolver = (_) async => d3;
      repo.emit([
        _command(
          id: 'c-streak',
          progress: 0,
          frequency: Frequency.daily,
          createdAt: d3,
        ),
      ]);

      await tester.pumpWidget(
        _wrap(
          provider: provider,
          eventRepository: eventsRepo,
          child: const CommandDetailPage(commandId: 'c-streak'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      eventsRepo.emit([
        _event(cycleKey: k1, type: CommandEventType.complete),
        _event(cycleKey: k2, type: CommandEventType.complete),
        _event(cycleKey: k3, type: CommandEventType.complete),
      ]);
      await tester.pump(const Duration(milliseconds: 120));

      expect(find.textContaining('jours réussis'), findsOneWidget);

      provider.dispose();
      repo.dispose();
      eventsRepo.dispose();
    });

    testWidgets('état vide si aucun historique et fallback createdAt absent', (
      tester,
    ) async {
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

    testWidgets(
      'navigation précédent/suivant en yearly met à jour la période',
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
      },
    );

    testWidgets('accessibilité: navigation lisible via tooltips', (
      tester,
    ) async {
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
    testWidgets('snackbar affichée uniquement si reset eu lieu', (
      tester,
    ) async {
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
      final fakeAuthRepo = _FakeAuthRepository(
        const AuthUser(uid: 'u1', email: 'a@b.c'),
      );
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

    testWidgets('création: tap hors champ puis Enregistrer soumet toujours', (
      tester,
    ) async {
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

    testWidgets('édition: soumission + gestion erreur repository', (
      tester,
    ) async {
      final cmd = _command(id: 'edit', progress: 1, target: 3);
      final repo = _FakeCommandRepository()..updateError = StateError('fail');
      final provider = CommandProvider(repository: repo)..addListener(() {});
      repo.emit([cmd]);
      final fakeAuthRepo = _FakeAuthRepository(
        const AuthUser(uid: 'u1', email: 'a@b.c'),
      );
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
      final submitButton = find.widgetWithText(FilledButton, 'Enregistrer');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(submitButton);
      await tester.pump();
      await tester.tap(submitButton);
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
