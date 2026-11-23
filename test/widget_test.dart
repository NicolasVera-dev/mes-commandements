// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:rituel/app/localization/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rituel/app/command_card_layout_service.dart';
import 'package:rituel/app/theme_service.dart';
import 'package:rituel/app/user_preferences_service.dart';
import 'package:rituel/main.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/entities/command_events_period.dart';
import 'package:rituel/features/commands/domain/entities/cycle_note.dart';
import 'package:rituel/features/commands/domain/repositories/command_event_repository.dart';
import 'package:rituel/features/commands/domain/repositories/cycle_note_repository.dart';
import 'package:rituel/features/notifications/data/notification_preferences_service.dart';
import 'package:rituel/features/notifications/domain/notification_scheduler.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.connected = false});
  final bool connected;
  @override
  Stream<AuthUser?> authStateChanges() => Stream<AuthUser?>.value(
    connected ? const AuthUser(uid: 'u1', email: 'test@example.com') : null,
  );

  @override
  Future<AuthUser> signUp({
    required String email,
    required String password,
  }) async => const AuthUser(uid: 'u1', email: 'test@example.com');

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async => const AuthUser(uid: 'u1', email: 'test@example.com');

  @override
  Future<void> signOut() async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount({required String currentPassword}) async {}
}

class _FakeCommandEventRepository implements CommandEventRepository {
  @override
  Stream<List<CommandEvent>> watchEvents(
    String commandId, {
    CommandEventsPeriod? period,
  }) => const Stream<List<CommandEvent>>.empty();

  @override
  Stream<List<CommandEvent>> watchEventsFrom(
    String commandId, {
    required DateTime startUtcInclusive,
  }) => const Stream<List<CommandEvent>>.empty();

  @override
  void addEventFireAndForget({
    required String commandId,
    required CommandEvent event,
  }) {}

  @override
  Future<void> deleteAllEvents(String commandId) async {}

  @override
  Future<DateTime?> firstEventAtUtc(String commandId) async => null;
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  testWidgets('language can be changed from actual account settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final language = LanguageService(preferences: preferences);
    final theme = ThemeService(prefs: preferences);
    final layout = CommandCardLayoutService(prefs: preferences);
    final firestore = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MyApp(
        authRepository: _FakeAuthRepository(connected: true),
        commandEventRepository: _FakeCommandEventRepository(),
        cycleNoteRepository: _FakeCycleNoteRepository(),
        themeService: theme,
        commandCardLayoutService: layout,
        userPreferencesService: UserPreferencesService(
          firestore: firestore,
          themeService: theme,
          commandCardLayoutService: layout,
        ),
        notificationScheduler: const NoOpNotificationScheduler(),
        notificationPreferencesService: NotificationPreferencesService(
          preferences,
        ),
        firestoreOverride: firestore,
        languageService: language,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Paramètres du compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Account settings'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres du compte'), findsOneWidget);
    expect(find.text('Apparence'), findsOneWidget);
    final restored = LanguageService(preferences: preferences);
    expect(restored.locale.languageCode, 'fr');
    restored.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    language.dispose();
  });

  testWidgets('Smoke test auth gate', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final themeService = ThemeService(prefs: prefs);
    final commandCardLayoutService = CommandCardLayoutService(prefs: prefs);
    final fakeFirestore = FakeFirebaseFirestore();
    await tester.pumpWidget(
      MyApp(
        authRepository: _FakeAuthRepository(),
        commandEventRepository: _FakeCommandEventRepository(),
        cycleNoteRepository: _FakeCycleNoteRepository(),
        themeService: themeService,
        commandCardLayoutService: commandCardLayoutService,
        userPreferencesService: UserPreferencesService(
          firestore: fakeFirestore,
          themeService: themeService,
          commandCardLayoutService: commandCardLayoutService,
        ),
        notificationScheduler: const NoOpNotificationScheduler(),
        notificationPreferencesService: NotificationPreferencesService(prefs),
        firestoreOverride: fakeFirestore,
      ),
    );
    await tester.pump();
  });
}
