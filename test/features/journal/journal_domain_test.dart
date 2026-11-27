import 'package:flutter_test/flutter_test.dart';
import 'package:rituel/features/journal/domain/entities/journal_day.dart';
import 'package:rituel/features/journal/domain/entities/journal_task.dart';
import 'package:rituel/features/journal/domain/entities/journal_reflection.dart';
import 'package:rituel/features/journal/domain/services/journal_day_summary.dart';

JournalDay day(String value) => JournalDay.parse(value);
JournalTask task({String id = 'task', String start = '2026-11-23'}) =>
    JournalTask(
      id: id,
      title: 'Envoyer le devis',
      plans: [JournalPlan(start: day(start))],
    );
JournalDaySummary summary(JournalTask task, String date) =>
    JournalDaySummary(tasks: [task], day: day(date));

void main() {
  test(
    'calendar arithmetic is stable across DST, year and leap boundaries',
    () {
      expect(day('2026-03-28').add(2), day('2026-03-30'));
      expect(day('2026-10-24').add(2).daysSince(day('2026-10-24')), 2);
      expect(day('2028-02-28').add(1), day('2028-02-29'));
      expect(day('2026-12-31').add(1), day('2027-01-01'));
      expect(() => day('2026-02-30'), throwsFormatException);
      expect(() => day('2026-1-2'), throwsFormatException);
      expect(
        JournalDay.fromDate(DateTime(2026, 11, 23, 23, 59)),
        day('2026-11-23'),
      );
    },
  );

  test('automatic carry requires no writes and preserves the original day', () {
    final t = task();
    expect(summary(t, '2026-11-22').tasks, isEmpty);
    expect(summary(t, '2026-11-23').score, 0);
    expect(summary(t, '2026-11-26').pending.single.id, t.id);
    expect(t.lateDaysOn(day('2026-11-26')), 3);
    expect(t.originalDay, day('2026-11-23'));
    expect(t.plans, hasLength(1));
  });

  test('completion counts on the actual day without rewriting missed days', () {
    final t = task().complete(day('2026-11-25'), done: true);
    expect(summary(t, '2026-11-23').score, 0);
    expect(summary(t, '2026-11-24').score, 0);
    expect(summary(t, '2026-11-25').score, 100);
    expect(summary(t, '2026-11-26').score, isNull);
    expect(() => t.complete(day('2026-11-26'), done: false), throwsStateError);
    final reopened = t.complete(day('2026-11-25'), done: false);
    expect(summary(reopened, '2026-11-25').score, 0);
    expect(summary(reopened, '2026-11-26').pending, hasLength(1));
  });

  test(
    'same-day deletion removes the denominator but retains prior failures',
    () {
      final removed = task().remove(day('2026-11-25'));
      expect(summary(removed, '2026-11-23').score, 0);
      expect(summary(removed, '2026-11-24').score, 0);
      expect(summary(removed, '2026-11-25').score, isNull);
      expect(summary(removed, '2026-11-26').tasks, isEmpty);
      expect(summary(removed.restore(), '2026-11-25').pending, hasLength(1));
    },
  );

  test('rescheduling closes history and excludes days before the new plan', () {
    final replanned = task().reschedule(day('2026-11-28'), day('2026-11-25'));
    expect(summary(replanned, '2026-11-24').score, 0);
    expect(summary(replanned, '2026-11-25').score, isNull);
    expect(summary(replanned, '2026-11-27').tasks, isEmpty);
    expect(summary(replanned, '2026-11-28').pending, hasLength(1));
    expect(replanned.lateDaysOn(day('2026-11-28')), 0);
    expect(replanned.originalDay, day('2026-11-23'));
    final again = replanned.reschedule(day('2026-12-01'), day('2026-11-29'));
    expect(summary(again, '2026-11-28').score, 0);
    expect(summary(again, '2026-11-29').score, isNull);
    expect(summary(again, '2026-11-30').score, isNull);
    expect(summary(again, '2026-12-01').pending, hasLength(1));
    expect(
      () => again.reschedule(day('2026-11-20'), day('2026-11-29')),
      throwsStateError,
    );
  });

  test('future tasks can be moved earlier without phantom history', () {
    final t = task(start: '2026-11-30')
        .reschedule(day('2026-11-26'), day('2026-11-25'));
    expect(t.plans, hasLength(1));
    expect(t.originalDay, day('2026-11-30'));
    expect(summary(t, '2026-11-25').tasks, isEmpty);
    expect(summary(t, '2026-11-26').tasks, hasLength(1));
    expect(() => t.complete(day('2026-11-25'), done: true), throwsStateError);
  });

  test(
    'scores have equal weights, null for empty days, and round percentages',
    () {
      final today = day('2026-11-23');
      final tasks = [
        task(id: 'a').complete(today, done: true),
        task(id: 'b').edit(priority: true),
        task(id: 'c'),
      ];
      expect(JournalDaySummary(tasks: tasks, day: today).score, 33);
      expect(JournalDaySummary(tasks: [], day: today).score, isNull);
    },
  );

  test('invalid titles, overlapping plans and oversized reflections fail', () {
    expect(() => task().edit(title: '  '), throwsArgumentError);
    expect(() => task().edit(title: 'a' * 201), throwsArgumentError);
    expect(
      () => JournalTask(
        id: 'bad',
        title: 'bad',
        plans: [
          JournalPlan(start: day('2026-11-23')),
          JournalPlan(start: day('2026-11-24')),
        ],
      ),
      throwsArgumentError,
    );
    expect(
      () => JournalReflection(day: day('2026-11-23'), note: 'a' * 4001),
      throwsArgumentError,
    );
  });
}
