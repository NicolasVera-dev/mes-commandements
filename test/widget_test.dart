// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mes_commandements/app/theme_service.dart';
import 'package:mes_commandements/app/user_preferences_service.dart';
import 'package:mes_commandements/main.dart';
import 'package:mes_commandements/features/auth/domain/entities/auth_user.dart';
import 'package:mes_commandements/features/auth/domain/repositories/auth_repository.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_event.dart';
import 'package:mes_commandements/features/commands/domain/entities/command_events_period.dart';
import 'package:mes_commandements/features/commands/domain/repositories/command_event_repository.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() => const Stream<AuthUser?>.empty();

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
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {}

  @override
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount({
    required String currentPassword,
  }) async {}
}

class _FakeCommandEventRepository implements CommandEventRepository {
  @override
  Stream<List<CommandEvent>> watchEvents(
    String commandId, {
    CommandEventsPeriod? period,
  }) =>
      const Stream<List<CommandEvent>>.empty();

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

void main() {
  testWidgets(
    'Smoke test auth gate (skipped)',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final themeService = ThemeService(prefs: prefs);
      await tester.pumpWidget(
        MyApp(
          authRepository: _FakeAuthRepository(),
          commandEventRepository: _FakeCommandEventRepository(),
          themeService: themeService,
          userPreferencesService: UserPreferencesService(
            themeService: themeService,
          ),
        ),
      );
      await tester.pump();
    },
    skip: true,
  );
}
