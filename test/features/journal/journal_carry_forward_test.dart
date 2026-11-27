import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/journal/domain/entities/journal_day.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/journal/domain/services/journal_day_summary.dart';
import 'package:rituel/features/journal/data/firestore_journal_repository.dart';

void main() {
  final monday = JournalDay.parse('2026-11-23');
  JournalTask task({bool carry = true}) => JournalTask(
    id: 'task',
    title: 'Devis',
    plans: [JournalPlan(start: monday, carryForward: carry)],
  );
  test('one-day tasks stay missed in history without carrying to tomorrow', () {
    final t = task(carry: false);
    expect(t.appearsOn(monday), true);
    expect(t.appearsOn(monday.add(1)), false);
    expect(JournalDaySummary(tasks: [t], day: monday).score, 0);
    expect(JournalDaySummary(tasks: [t], day: monday.add(1)).score, isNull);
    expect(() => t.complete(monday.add(1), done: true), throwsStateError);
    expect(t.complete(monday, done: true).completedOn(monday), true);
  });
  test(
    'changing carry policy preserves past commitments and current order',
    () {
      final changed = task().withCarryForward(false, monday.add(2));
      expect(changed.appearsOn(monday), true);
      expect(changed.appearsOn(monday.add(1)), true);
      expect(changed.appearsOn(monday.add(2)), true);
      expect(changed.appearsOn(monday.add(3)), false);
      expect(changed.plans.first.carryForward, true);
      expect(changed.carryForward, false);
      final rescheduled = changed.reschedule(monday.add(5), monday.add(2));
      expect(rescheduled.appearsOn(monday.add(5)), true);
      expect(rescheduled.appearsOn(monday.add(6)), false);
      final restored = task(carry: false).withCarryForward(true, monday);
      expect(restored.appearsOn(monday.add(10)), true);
    },
  );
  test(
    'Firestore persists the policy and old tasks default to carry enabled',
    () async {
      final db = FakeFirebaseFirestore();
      final repo = FirestoreJournalRepository(firestore: db);
      await repo.saveTask('u', task(carry: false));
      expect((await repo.watchTasks('u').first).single.carryForward, false);
      await db.doc('users/u/journal_tasks/task').update({
        'plans': [
          {'start': monday.key, 'end': null},
        ],
      });
      expect((await repo.watchTasks('u').first).single.carryForward, true);
    },
  );
}
