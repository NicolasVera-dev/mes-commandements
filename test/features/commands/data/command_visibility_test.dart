import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/auth/domain/entities/auth_user.dart';
import 'package:rituel/features/auth/domain/repositories/auth_repository.dart';
import 'package:rituel/features/commands/data/repositories/firestore_command_repository.dart';
import 'package:rituel/features/commands/domain/entities/command.dart';
import 'package:rituel/features/commands/domain/entities/command_pause.dart';
import 'package:rituel/features/commands/domain/usecases/filter_and_sort_commands_usecase.dart';

class _Auth extends Fake implements AuthRepository {
  @override
  Stream<AuthUser?> authStateChanges() =>
      Stream.value(const AuthUser(uid: 'u', email: 'u@example.com'));
}

Command command({
  String id = 'steps',
  bool hidden = false,
  int progress = 2,
  List<CommandPause> pauses = const [],
}) => Command(
  id: id,
  title: 'Faire 7k pas',
  description: 'Mon ancien objectif',
  target: 7,
  progress: progress,
  frequency: Frequency.daily,
  isHidden: hidden,
  pauses: pauses,
  createdAt: DateTime.utc(2026, 1, 1),
  lastResetAt: DateTime.utc(2026, 1, 1),
);

void main() {
  test('old records stay visible and visibility survives maps, copies and equality', () {
    final old = command().toMap()..remove('isHidden');
    expect(Command.fromMap(id: 'steps', map: old).isHidden, false);
    final hidden = command().copyWith(isHidden: true);
    expect(hidden, isNot(command()));
    expect(Command.fromMap(id: hidden.id, map: hidden.toMap()), hidden);
    expect(hidden.copyWith(title: '7k').isHidden, true);
    expect(hidden.shouldAutoReset(DateTime.utc(2026, 11, 27)), false);
  });

  test('hide preserves old pause intervals and extends active scheduled pause indefinitely', () {
    final now = DateTime.utc(2026, 11, 25);
    final past = CommandPause(
      startUtc: now.subtract(const Duration(days: 10)),
      endUtc: now.subtract(const Duration(days: 7)),
    );
    final active = CommandPause(
      startUtc: now.subtract(const Duration(days: 1)),
      endUtc: now.add(const Duration(days: 1)),
    );
    final hidden = command(pauses: [past, active]).hideAt(now);
    expect(hidden.pauses, hasLength(2));
    expect(hidden.pauses.first, past);
    expect(hidden.pauses.last.startUtc, active.startUtc);
    expect(hidden.pauses.last.endUtc, null);
    expect(hidden.hideAt(now), hidden);
    expect(hidden.wasPausedAtCycleEnd(DateTime.utc(2026, 11, 20)), false);
  });

  test('hide is atomic, stops resets and progress, and show keeps indefinite pause', () async {
    final db = FakeFirebaseFirestore();
    final repo = FirestoreCommandRepository(
      authRepository: _Auth(),
      firestore: db,
    );
    final ref = db.doc('users/u/commands/steps');
    final now = DateTime.now().toUtc();
    final original = command(
      pauses: [
        CommandPause(
          startUtc: now.subtract(const Duration(days: 1)),
          endUtc: now.add(const Duration(days: 1)),
        ),
      ],
    );
    await ref.set(original.toMap());
    await ref.collection('events').doc('old').set({'kept': true});
    await ref.collection('cycle_notes').doc('old').set({'content': 'Souvenir'});
    await repo.setHidden('steps', hidden: true);
    var hidden = Command.fromMap(id: 'steps', map: (await ref.get()).data()!);
    expect(hidden.isHidden, true);
    expect(hidden.pauses.single.startUtc, original.pauses.single.startUtc);
    expect(hidden.pauses.single.endUtc, null);
    expect(hidden.title, original.title);
    expect(hidden.target, original.target);
    expect(hidden.progress, original.progress);
    expect(hidden.lastResetAt, original.lastResetAt);
    await repo.setHidden('steps', hidden: true);
    await repo.incrementProgress('steps');
    await repo.resetProgress('steps');
    await repo.resume('steps', nextCycle: false);
    await repo.resume('steps', nextCycle: true);
    expect(
      (await repo.applyPendingAutoResets(now.add(const Duration(days: 100))))
          .hasResets,
      false,
    );
    hidden = Command.fromMap(id: 'steps', map: (await ref.get()).data()!);
    expect(hidden.isHidden, true);
    expect(hidden.progress, original.progress);
    expect(hidden.pauses, hasLength(1));
    expect((await ref.collection('events').get()).docs, hasLength(1));
    expect((await ref.collection('cycle_notes').get()).docs, hasLength(1));
    await repo.setHidden('steps', hidden: false);
    final shown = Command.fromMap(id: 'steps', map: (await ref.get()).data()!);
    expect(shown.isHidden, false);
    expect(shown.isPausedAt(now.add(const Duration(days: 10))), true);
    expect(shown.progress, original.progress);
    await repo.resume('steps', nextCycle: false);
    expect(
      Command.fromMap(
        id: 'steps',
        map: (await ref.get()).data()!,
      ).isPausedAt(DateTime.now()),
      false,
    );
  });

  test('hidden commands are excluded by default and paused filtering uses pause before progress', () {
    final now = DateTime.utc(2026, 11, 25);
    final list = [
      command(id: 'visible'),
      command(id: 'hidden').hideAt(now),
      command(
        id: 'paused',
        progress: 7,
        pauses: [CommandPause(startUtc: now)],
      ),
      command(
        id: 'expired',
        pauses: [
          CommandPause(
            startUtc: now.subtract(const Duration(days: 2)),
            endUtc: now,
          ),
        ],
      ),
    ];
    List<String> filtered({
      Set<CommandStatusFilter> statuses = const {},
      bool hiddenOnly = false,
    }) => const FilterAndSortCommandsUseCase()
        .execute(
          commands: list,
          frequencies: null,
          statuses: statuses,
          tags: {},
          sort: CommandSort.alpha,
          searchQuery: '',
          hiddenOnly: hiddenOnly,
          now: now,
        )
        .map((c) => c.id)
        .toList();
    expect(filtered(), unorderedEquals(['expired', 'paused', 'visible']));
    expect(filtered(statuses: {CommandStatusFilter.paused}), ['paused']);
    expect(
      filtered(statuses: {CommandStatusFilter.started}),
      unorderedEquals(['expired', 'visible']),
    );
    expect(filtered(statuses: {CommandStatusFilter.completed}), isEmpty);
    expect(filtered(statuses: {CommandStatusFilter.paused}, hiddenOnly: true), [
      'hidden',
    ]);
    expect(
      filtered(statuses: {CommandStatusFilter.all}),
      unorderedEquals(['expired', 'paused', 'visible']),
    );
  });

  test(
    'permanent deletion purges more than one batch of events and notes',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreCommandRepository(
        authRepository: _Auth(),
        firestore: db,
      );
      final ref = db.doc('users/u/commands/steps');
      await ref.set(command().hideAt(DateTime.now()).toMap());
      for (var i = 0; i < 505; i++) {
        await ref.collection('events').doc('$i').set({'index': i});
        await ref.collection('cycle_notes').doc('$i').set({
          'content': 'Note $i',
        });
      }
      await db.doc('users/other/commands/steps').set(command().toMap());
      await repo.delete('steps');
      expect((await ref.get()).exists, false);
      expect((await ref.collection('events').get()).docs, isEmpty);
      expect((await ref.collection('cycle_notes').get()).docs, isEmpty);
      expect((await db.doc('users/other/commands/steps').get()).exists, true);
    },
  );
}
