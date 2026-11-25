import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/journal_day.dart';
import '../domain/entities/journal_reflection.dart';
import '../domain/entities/journal_task.dart';
import '../domain/repositories/journal_repository.dart';

class FirestoreJournalRepository implements JournalRepository {
  final FirebaseFirestore _firestore;
  FirestoreJournalRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _firestore.collection('users/$uid/journal_tasks');
  CollectionReference<Map<String, dynamic>> _reflections(String uid) =>
      _firestore.collection('users/$uid/journal_reflections');

  @override
  String newTaskId(String userId) => _tasks(userId).doc().id;

  @override
  Stream<List<JournalTask>> watchTasks(String userId) =>
      _tasks(userId).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return JournalTask(
            id: doc.id,
            title: data['title'] as String,
            priority: data['priority'] as bool? ?? false,
            order: (data['order'] as num?)?.toDouble() ?? 0,
            plans: (data['plans'] as List).map((raw) {
              final plan = Map<String, dynamic>.from(raw as Map);
              return JournalPlan(
                start: JournalDay.parse(plan['start'] as String),
                end: _day(plan['end']),
              );
            }).toList(),
            originalDay: _day(data['originalDay']),
            completedDay: _day(data['completedDay']),
            removedDay: _day(data['removedDay']),
          );
        }).toList(),
      );

  static JournalDay? _day(Object? value) =>
      value == null ? null : JournalDay.parse(value as String);

  @override
  Stream<List<JournalReflection>> watchReflections(String userId) =>
      _reflections(userId).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return JournalReflection(
            day: JournalDay.parse(doc.id),
            note: data['note'] as String? ?? '',
            mood: JournalMood.values
                .where((m) => m.name == data['mood'])
                .firstOrNull,
          );
        }).toList(),
      );

  @override
  Future<void> saveTask(String userId, JournalTask task) =>
      _tasks(userId).doc(task.id).set({
        'title': task.title,
        'priority': task.priority,
        'order': task.order,
        'plans': task.plans
            .map((p) => {'start': p.start.key, 'end': p.end?.key})
            .toList(),
        'originalDay': task.originalDay.key,
        'completedDay': task.completedDay?.key,
        'removedDay': task.removedDay?.key,
      });

  @override
  Future<void> reorder(String userId, List<JournalTask> tasks) async {
    // Only the ordering field changes; completion and content stay untouched.
    for (var start = 0; start < tasks.length; start += 450) {
      final batch = _firestore.batch();
      for (final task in tasks.skip(start).take(450)) {
        batch.update(_tasks(userId).doc(task.id), {'order': task.order});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> saveReflection(String userId, JournalReflection reflection) =>
      _reflections(userId)
          .doc(reflection.day.key)
          .set({'note': reflection.note, 'mood': reflection.mood?.name});
}
