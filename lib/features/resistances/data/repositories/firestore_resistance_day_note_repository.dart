import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/resistance_day_note.dart';
import '../../domain/repositories/resistance_day_note_repository.dart';

class FirestoreResistanceDayNoteRepository implements ResistanceDayNoteRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreResistanceDayNoteRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _notesCollection({
    required String uid,
    required String resistanceId,
  }) {
    return _firestore.collection('users/$uid/resistances/$resistanceId/day_notes');
  }

  Future<String?> _currentUserId() async {
    final user = await _authRepository.authStateChanges().first;
    return user?.uid;
  }

  static const int _whereInChunkSize = 30;

  @override
  Stream<Map<String, ResistanceDayNote>> watchNotes(
    String resistanceId, {
    required Set<String> dayKeys,
  }) {
    final keys = dayKeys.toList()..sort();
    if (keys.isEmpty) {
      return Stream<Map<String, ResistanceDayNote>>.value(<String, ResistanceDayNote>{});
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < keys.length; i += _whereInChunkSize) {
      final end =
          i + _whereInChunkSize > keys.length ? keys.length : i + _whereInChunkSize;
      chunks.add(keys.sublist(i, end));
    }

    final controller = StreamController<Map<String, ResistanceDayNote>>();
    StreamSubscription<AuthUser?>? authSub;
    final chunkSubs = <StreamSubscription<QuerySnapshot<Map<String, Object?>>>>[];
    final perChunk =
        List<Map<String, ResistanceDayNote>>.generate(chunks.length, (_) => <String, ResistanceDayNote>{});

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = <String, ResistanceDayNote>{};
      for (final m in perChunk) {
        merged.addAll(m);
      }
      controller.add(merged);
    }

    Future<void> startForUser(AuthUser? user) async {
      for (final s in chunkSubs) {
        await s.cancel();
      }
      chunkSubs.clear();
      for (var i = 0; i < perChunk.length; i++) {
        perChunk[i].clear();
      }

      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<String, ResistanceDayNote>{});
        return;
      }

      for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        final chunk = chunks[chunkIndex];
        final query = _notesCollection(uid: user.uid, resistanceId: resistanceId)
            .where('dayKey', whereIn: chunk);

        final sub = query.snapshots().listen(
          (snapshot) {
            perChunk[chunkIndex].clear();
            for (final doc in snapshot.docs) {
              final note = _fromDoc(resistanceId: resistanceId, doc: doc);
              perChunk[chunkIndex][note.dayKey] = note;
            }
            emitMerged();
          },
          onError: controller.addError,
        );
        chunkSubs.add(sub);
      }
    }

    authSub = _authRepository.authStateChanges().listen(
      startForUser,
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await authSub?.cancel();
      for (final s in chunkSubs) {
        await s.cancel();
      }
      chunkSubs.clear();
    };

    return controller.stream;
  }

  ResistanceDayNote _fromDoc({
    required String resistanceId,
    required QueryDocumentSnapshot<Map<String, Object?>> doc,
  }) {
    final data = doc.data();
    final key = (data['dayKey'] ?? doc.id).toString();
    final content = (data['content'] ?? '').toString();
    final updatedRaw = data['updatedAtUtc'];
    final updatedAtUtc = _parseUtc(updatedRaw) ?? DateTime.utc(1970, 1, 1);
    return ResistanceDayNote(
      resistanceId: resistanceId,
      dayKey: key,
      content: content,
      updatedAtUtc: updatedAtUtc,
    );
  }

  DateTime? _parseUtc(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  @override
  Future<void> saveNote(ResistanceDayNote note) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final docRef =
        _notesCollection(uid: uid, resistanceId: note.resistanceId).doc(note.dayKey);
    await docRef.set(<String, Object?>{
      'dayKey': note.dayKey,
      'content': note.content,
      'updatedAtUtc': Timestamp.fromDate(note.updatedAtUtc.toUtc()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteNote({
    required String resistanceId,
    required String dayKey,
  }) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _notesCollection(uid: uid, resistanceId: resistanceId).doc(dayKey).delete();
  }

  @override
  Future<void> deleteAllForResistance(String resistanceId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final col = _notesCollection(uid: uid, resistanceId: resistanceId);
    const batchSize = 500;
    while (true) {
      final snapshot = await col.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < batchSize) break;
    }
  }
}
