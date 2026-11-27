import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/journal/domain/entities/journal_reflection.dart';
import 'package:rituel/features/journal/presentation/state/journal_provider.dart';

Future<void> waitUntil(
  JournalProvider provider,
  bool Function() predicate,
) async {
  if (predicate()) return;
  final completer = Completer<void>();
  void listener() {
    if (predicate() && !completer.isCompleted) completer.complete();
  }

  provider.addListener(listener);
  try {
    await completer.future.timeout(const Duration(seconds: 3));
  } finally {
    provider.removeListener(listener);
  }
}

class _FailingRepository extends FirestoreJournalRepository {
  bool fail = false;
  Completer<void>? pending;
  _FailingRepository(FakeFirebaseFirestore firestore)
    : super(firestore: firestore);
  @override
  Future<void> saveTask(String userId, JournalTask task) async {
    if (fail) throw StateError('unavailable');
    if (pending != null) await pending!.future;
    await super.saveTask(userId, task);
  }
}

void main() {
  test(
    'midnight carry, reordering, completion and reload preserve daily scores',
    () async {
      final repo = FirestoreJournalRepository(
        firestore: FakeFirebaseFirestore(),
      );
      var now = DateTime(2026, 11, 23, 23, 59);
      final provider = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => now,
      );
      await waitUntil(
        provider,
        () => provider.isConnected && !provider.isLoading,
      );
      final monday = provider.today;
      await provider.add(title: 'Devis', day: monday);
      await provider.add(title: 'Courses', day: monday, priority: true);
      await waitUntil(
        provider,
        () => provider.summary(monday).tasks.length == 2,
      );
      final reversed = provider
          .summary(monday)
          .tasks
          .reversed
          .map((t) => t.id)
          .toList();
      await provider.reorder(reversed);
      await waitUntil(
        provider,
        () => provider.summary(monday).tasks.first.id == reversed.first,
      );
      final id = provider.summary(monday).tasks.first.id;
      await provider.toggle(id, true);
      await waitUntil(provider, () => provider.summary(monday).score == 50);
      now = DateTime(2026, 11, 24, 0, 1);
      provider.refreshDay();
      expect(provider.summary(provider.today).pending, hasLength(1));
      final remaining = provider.summary(provider.today).tasks.single;
      expect(remaining.lateDaysOn(provider.today), 1);
      expect(provider.summary(monday).score, 50);
      await expectLater(provider.toggle(id, false), throwsStateError);
      await provider.toggle(remaining.id, true);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).score == 100,
      );
      await provider.saveReflection(
        JournalReflection(
          day: provider.today,
          note: 'Fier du travail accompli',
          mood: JournalMood.satisfied,
        ),
      );
      provider.dispose();
      final restarted = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => now,
      );
      await waitUntil(
        restarted,
        () => restarted.isConnected && !restarted.isLoading,
      );
      expect(restarted.summary(monday).score, 50);
      expect(restarted.summary(restarted.today).score, 100);
      expect(
        restarted.reflection(restarted.today)?.mood,
        JournalMood.satisfied,
      );
      restarted.dispose();
    },
  );

  test(
    'replanning and deleting retain past scores; undo restores today',
    () async {
      final provider = JournalProvider(
        repository: FirestoreJournalRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        userIds: Stream.value('a'),
        clock: () => DateTime(2026, 11, 25),
      );
      await waitUntil(
        provider,
        () => provider.isConnected && !provider.isLoading,
      );
      await provider.add(title: 'Devis', day: provider.today);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).tasks.isNotEmpty,
      );
      final task = provider.summary(provider.today).tasks.single;
      final removed = await provider.remove(task.id);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).tasks.isEmpty,
      );
      await provider.restore(removed);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).tasks.isNotEmpty,
      );
      await provider.reschedule(task.id, provider.today.add(2));
      await waitUntil(
        provider,
        () => provider.summary(provider.today).tasks.isEmpty,
      );
      expect(
        provider.summary(provider.today.add(2)).tasks.single.originalDay,
        provider.today,
      );
      expect(
        () => provider.add(title: 'Past', day: provider.today.add(-1)),
        throwsArgumentError,
      );
      provider.dispose();
    },
  );

  test('switching accounts clears tasks and reflections, including outstanding writes', () async {
    final users = StreamController<String?>();
    final db = FakeFirebaseFirestore();
    final repo = _FailingRepository(db);
    final provider = JournalProvider(
      repository: repo,
      userIds: users.stream,
      clock: () => DateTime(2026, 11, 25),
    );
    users.add('a');
    await waitUntil(
      provider,
      () => provider.isConnected && !provider.isLoading,
    );
    await provider.add(title: 'Privé', day: provider.today);
    await waitUntil(
      provider,
      () => provider.summary(provider.today).tasks.length == 1,
    );
    repo.pending = Completer<void>();
    final write = provider.add(
      title: 'Autre tâche privée',
      day: provider.today,
    );
    users.add('b');
    await Future<void>.delayed(Duration.zero);
    await waitUntil(provider, () => !provider.isLoading);
    expect(provider.summary(provider.today).tasks, isEmpty);
    repo.pending!.complete();
    await write;
    expect(provider.summary(provider.today).tasks, isEmpty);
    expect(provider.isSaving, false);
    users.add(null);
    await waitUntil(provider, () => !provider.isConnected);
    expect(provider.reflection(provider.today), isNull);
    await expectLater(
      provider.add(title: 'No user', day: provider.today),
      throwsStateError,
    );
    provider.dispose();
    await users.close();
  });

  test(
    'failed mutations release busy state and retain the existing task',
    () async {
      final repo = _FailingRepository(FakeFirebaseFirestore());
      final provider = JournalProvider(
        repository: repo,
        userIds: Stream.value('a'),
        clock: () => DateTime(2026, 11, 25),
      );
      await waitUntil(
        provider,
        () => provider.isConnected && !provider.isLoading,
      );
      await provider.add(title: 'Devis', day: provider.today);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).tasks.isNotEmpty,
      );
      repo.fail = true;
      final id = provider.summary(provider.today).tasks.single.id;
      await expectLater(provider.toggle(id, true), throwsStateError);
      expect(provider.isSaving, false);
      expect(provider.summary(provider.today).score, 0);
      repo.fail = false;
      await provider.toggle(id, true);
      await waitUntil(
        provider,
        () => provider.summary(provider.today).score == 100,
      );
      provider.dispose();
    },
  );
}
