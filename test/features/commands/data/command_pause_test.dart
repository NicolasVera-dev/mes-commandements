import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/commands/data/repositories/firestore_command_repository.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_event.dart';
import 'package:rituel/features/commands/domain/entities/command_pause.dart';
import 'package:rituel/features/commands/domain/services/cycle_key_generator.dart';
import 'package:rituel/features/commands/domain/usecases/build_cycle_summary_usecase.dart';
import 'package:rituel/features/commands/domain/usecases/compute_streak_usecase.dart';

class _SignedIn extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'tester', email: 'test@example.com'));
}

Command _command(DateTime createdAt, {List<CommandPause> pauses = const []}) =>
    Command(
      id: 'lecture',
      title: 'Lecture',
      frequency: Frequency.daily,
      target: 3,
      progress: 2,
      lastResetAt: createdAt,
      createdAt: createdAt,
      pauses: pauses,
    );

void main() {
  test(
    'suspend les mutations et conserve la progression à la reprise immédiate',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repo = FirestoreCommandRepository(
        authRepository: _SignedIn(),
        firestore: firestore,
      );
      final doc = firestore.doc('users/tester/commands/lecture');
      final now = DateTime.now().toUtc();
      await doc.set(_command(now).toMap());

      await repo.pause('lecture');
      await repo.pause(
        'lecture',
      ); // Un second appel ne crée pas une deuxième pause.
      await repo.incrementProgress('lecture');
      await repo.resetProgress('lecture');
      final paused = Command.fromMap(
        id: doc.id,
        map: (await doc.get()).data()!,
      );
      expect(paused.isPausedAt(DateTime.now()), isTrue);
      expect(paused.pauses, hasLength(1));
      expect(paused.progress, 2);
      expect(
        paused.shouldAutoReset(DateTime.now().add(const Duration(days: 2))),
        isFalse,
      );

      await repo.resume('lecture', nextCycle: false);
      final resumed = Command.fromMap(
        id: doc.id,
        map: (await doc.get()).data()!,
      );
      expect(resumed.isPausedAt(DateTime.now()), isFalse);
      expect(resumed.progress, 2);
      expect(resumed.pauses.single.endUtc, isNotNull);
      await repo.incrementProgress('lecture');
      expect((await doc.get()).data()!['progress'], 3);
    },
  );

  test('la reprise au prochain cycle ignore le cycle en cours et expire à la limite', () async {
    final firestore = FakeFirebaseFirestore();
    final repo = FirestoreCommandRepository(
      authRepository: _SignedIn(),
      firestore: firestore,
    );
    final doc = firestore.doc('users/tester/commands/lecture');
    final now = DateTime.now().toUtc();
    await doc.set(_command(now).toMap());
    await repo.pause('lecture', untilUtc: now.add(const Duration(days: 4)));
    await repo.resume('lecture', nextCycle: true);
    final command = Command.fromMap(id: doc.id, map: (await doc.get()).data()!);

    final end = CycleKeyGenerator.nextCycleStartUtc(Frequency.daily, now);
    expect(command.pauses.single.endUtc, end);
    expect(command.isPausedAt(now.add(const Duration(seconds: 2))), isTrue);
    expect(command.wasPausedAtCycleEnd(now), isTrue);
    expect(command.isPausedAt(end), isFalse);
    expect(command.applyAutoResetIfNeeded(end).progress, 0);
  });

  test('la série et le bilan ignorent les cycles suspendus sans perdre les réussites', () {
    final created = DateTime.utc(2026, 4, 1);
    final now = DateTime.utc(2026, 4, 5, 12);
    final command = _command(
      created,
      pauses: [
        CommandPause(
          startUtc: DateTime.utc(2026, 4, 2, 18),
          endUtc: DateTime.utc(2026, 4, 5),
        ),
      ],
    );
    final grouped = {
      for (final day in [1, 2, 5])
        '2026-04-0$day': [
          command.toEvent(
            type: CommandEventType.complete,
            actionAtUtc: DateTime.utc(2026, 4, day, 12),
          ),
        ],
    };

    final streak = const ComputeStreakUseCase().execute(
      command: command,
      grouped: grouped,
      createdAtUtc: created,
      nowUtc: now,
    );
    final summary = const BuildCycleSummaryUseCase().execute(
      frequency: Frequency.daily,
      anchorUtc: now,
      grouped: grouped,
      currentKey: command.cycleKeyAt(now),
      createdAtUtc: created,
      nowUtc: now,
      wasPausedAtCycleEnd: command.wasPausedAtCycleEnd,
    );
    expect(streak.badge, StreakBadge.inRhythm);
    expect(streak.count, 3);
    expect(summary.success, 3);
    expect(summary.failed, 0);
  });
}
