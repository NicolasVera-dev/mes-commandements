import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';
import 'package:rituel/features/journal/domain/entities/journal_day.dart';
import 'package:rituel/features/journal/domain/entities/journal_reflection.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/auth/data/repositories/firestore_account_data_cleanup_repository.dart';

void main() {
  test(
    'Firestore round trip preserves plans, deletion, completion and user scope',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreJournalRepository(firestore: db);
      final start = JournalDay.parse('2026-11-23');
      final task =
          JournalTask(
                id: repo.newTaskId('a'),
                title: '  Devis  ',
                priority: true,
                order: 3,
                plans: [JournalPlan(start: start)],
              )
              .reschedule(start.add(4), start.add(2))
              .complete(start.add(4), done: true)
              .remove(start.add(4));
      await repo.saveTask('a', task);
      final read = (await repo.watchTasks('a').first).single;
      expect(read.title, 'Devis');
      expect(read.priority, true);
      expect(read.plans, hasLength(2));
      expect(read.plans.first.end, start.add(1));
      expect(read.completedDay, start.add(4));
      expect(read.removedDay, start.add(4));
      expect(await repo.watchTasks('b').first, isEmpty);
      await repo.saveReflection(
        'a',
        JournalReflection(
          day: start,
          note: ' Une réussite ',
          mood: JournalMood.satisfied,
        ),
      );
      final reflection = (await repo.watchReflections('a').first).single;
      expect(reflection.note, 'Une réussite');
      expect(reflection.mood, JournalMood.satisfied);
      expect(await repo.watchReflections('b').first, isEmpty);
      await repo.reorder('a', [read.edit(order: 1)]);
      final reordered = (await repo.watchTasks('a').first).single;
      expect(reordered.order, 1);
      expect(reordered.completedDay, start.add(4));
    },
  );

  test(
    'account cleanup removes journal data only for the deleted user',
    () async {
      final db = FakeFirebaseFirestore();
      for (final uid in ['a', 'b']) {
        await db.doc('users/$uid/journal_tasks/task').set({'title': 'Devis'});
        await db.doc('users/$uid/journal_reflections/2026-11-23').set({
          'note': 'Bilan',
        });
      }
      await FirestoreAccountDataCleanupRepository(firestore: db)
          .deleteAllUserData(uid: 'a');
      expect(
        (await db.collection('users/a/journal_tasks').get()).docs,
        isEmpty,
      );
      expect(
        (await db.collection('users/a/journal_reflections').get()).docs,
        isEmpty,
      );
      expect(
        (await db.collection('users/b/journal_tasks').get()).docs,
        hasLength(1),
      );
      expect(
        (await db.collection('users/b/journal_reflections').get()).docs,
        hasLength(1),
      );
    },
  );
}
