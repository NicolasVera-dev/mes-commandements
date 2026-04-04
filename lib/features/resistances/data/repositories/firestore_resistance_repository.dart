import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/resistance.dart';
import '../../domain/entities/resistance_position_update.dart';
import '../../domain/repositories/resistance_repository.dart';

class FirestoreResistanceRepository implements ResistanceRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreResistanceRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _collectionForUser(String uid) {
    return _firestore.collection('users/$uid/resistances');
  }

  CollectionReference<Map<String, Object?>> _relapsesCollection({
    required String uid,
    required String resistanceId,
  }) {
    return _firestore.collection('users/$uid/resistances/$resistanceId/relapses');
  }

  CollectionReference<Map<String, Object?>> _dayNotesCollection({
    required String uid,
    required String resistanceId,
  }) {
    return _firestore.collection('users/$uid/resistances/$resistanceId/day_notes');
  }

  Future<String?> _currentUserId() async {
    final user = await _authRepository.authStateChanges().first;
    return user?.uid;
  }

  Future<void> _purgeSubcollection(
    CollectionReference<Map<String, Object?>> collection,
  ) async {
    const batchSize = 500;
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < batchSize) return;
    }
  }

  Map<String, Object?> _resistanceWriteMap(Resistance r) {
    return <String, Object?>{
      'title': r.title,
      'description': r.description,
      'createdAtUtc': Timestamp.fromDate(r.createdAtUtc.toUtc()),
      'emoji': r.emoji,
      'accentColorValue': r.accentColorValue,
      'position': r.position,
      'tags': r.tags,
      'lastRelapseAtUtc': r.lastRelapseAtUtc != null
          ? Timestamp.fromDate(r.lastRelapseAtUtc!.toUtc())
          : null,
      'bestStreakDays': r.bestStreakDays,
    };
  }

  @override
  Stream<List<Resistance>> watchAll() {
    final controller = StreamController<List<Resistance>>();
    StreamSubscription<AuthUser?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? sub;

    Future<void> startForUser(AuthUser? user) async {
      await sub?.cancel();
      sub = null;
      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<Resistance>[]);
        return;
      }

      final collection = _collectionForUser(user.uid);
      sub = collection.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => Resistance.fromMap(
                  id: doc.id,
                  map: Map<String, Object?>.from(doc.data()),
                ),
              )
              .toList();
          list.sort((a, b) => a.position.compareTo(b.position));
          controller.add(list);
        },
        onError: controller.addError,
      );
    }

    authSub = _authRepository.authStateChanges().listen(
      startForUser,
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await authSub?.cancel();
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> add(Resistance resistance) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final collection = _collectionForUser(uid);
    final snapshot = await collection
        .orderBy('position', descending: true)
        .limit(1)
        .get();
    final maxPosition = snapshot.docs.isEmpty
        ? -1
        : Resistance.fromMap(
            id: snapshot.docs.first.id,
            map: Map<String, Object?>.from(snapshot.docs.first.data()),
          ).position;
    final withPosition = resistance.copyWith(
      position: maxPosition + 1,
      createdAtUtc: resistance.createdAtUtc,
    );
    await collection.doc(resistance.id).set(_resistanceWriteMap(withPosition));
  }

  @override
  Future<void> update(Resistance resistance) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _collectionForUser(uid)
        .doc(resistance.id)
        .update(_resistanceWriteMap(resistance));
  }

  @override
  Future<void> delete(String resistanceId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final ref = _collectionForUser(uid).doc(resistanceId);
    await _purgeSubcollection(_relapsesCollection(uid: uid, resistanceId: resistanceId));
    await _purgeSubcollection(_dayNotesCollection(uid: uid, resistanceId: resistanceId));
    await ref.delete();
  }

  @override
  Future<void> updatePositions(List<ResistancePositionUpdate> updates) async {
    final uid = await _currentUserId();
    if (uid == null || updates.isEmpty) return;
    final collection = _collectionForUser(uid);
    const maxBatchSize = 500;
    for (var i = 0; i < updates.length; i += maxBatchSize) {
      final end = i + maxBatchSize > updates.length ? updates.length : i + maxBatchSize;
      final chunk = updates.sublist(i, end);
      final batch = _firestore.batch();
      for (final u in chunk) {
        batch.update(collection.doc(u.resistanceId), <String, Object?>{
          'position': u.position,
        });
      }
      await batch.commit();
    }
  }

  @override
  Future<void> recordRelapse({
    required String resistanceId,
    required DateTime relapsedAtUtc,
    required int previousStreakDays,
    required int newBestStreakDays,
    String? note,
  }) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    final relapses = _relapsesCollection(uid: uid, resistanceId: resistanceId);
    final newId = relapses.doc().id;
    final batch = _firestore.batch();
    batch.set(relapses.doc(newId), <String, Object?>{
      'relapsedAtUtc': Timestamp.fromDate(relapsedAtUtc.toUtc()),
      'previousStreakDays': previousStreakDays,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    batch.update(_collectionForUser(uid).doc(resistanceId), <String, Object?>{
      'lastRelapseAtUtc': Timestamp.fromDate(relapsedAtUtc.toUtc()),
      'bestStreakDays': newBestStreakDays,
    });
    try {
      await batch.commit();
    } catch (e, st) {
      developer.log(
        'Erreur recordRelapse ($resistanceId): $e',
        name: 'FirestoreResistanceRepository',
        stackTrace: st,
      );
      rethrow;
    }
  }
}
