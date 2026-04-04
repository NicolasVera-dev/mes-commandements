import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/cycle_note.dart';
import '../../domain/repositories/cycle_note_repository.dart';

class FirestoreCycleNoteRepository implements CycleNoteRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreCycleNoteRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _notesCollection({
    required String uid,
    required String commandId,
  }) {
    return _firestore.collection('users/$uid/commands/$commandId/cycle_notes');
  }

  Future<String?> _currentUserId() async {
    final user = await _authRepository.authStateChanges().first;
    return user?.uid;
  }

  static const int _whereInChunkSize = 30;

  @override
  Stream<Map<String, CycleNote>> watchNotes(
    String commandId, {
    required Set<String> cycleKeys,
  }) {
    final keys = cycleKeys.toList()..sort();
    if (keys.isEmpty) {
      return Stream<Map<String, CycleNote>>.value(<String, CycleNote>{});
    }

    final chunks = <List<String>>[];
    for (var i = 0; i < keys.length; i += _whereInChunkSize) {
      final end = i + _whereInChunkSize > keys.length ? keys.length : i + _whereInChunkSize;
      chunks.add(keys.sublist(i, end));
    }

    final controller = StreamController<Map<String, CycleNote>>();
    StreamSubscription<AuthUser?>? authSub;
    final chunkSubs = <StreamSubscription<QuerySnapshot<Map<String, Object?>>>>[];
    final perChunk = List<Map<String, CycleNote>>.generate(
      chunks.length,
      (_) => <String, CycleNote>{},
    );

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = <String, CycleNote>{};
      for (final m in perChunk) {
        merged.addAll(m);
      }
      controller.add(merged);
    }

    Future<void> startForUser(AuthUser? user) async {
      for (final sub in chunkSubs) {
        await sub.cancel();
      }
      chunkSubs.clear();
      for (var i = 0; i < perChunk.length; i++) {
        perChunk[i].clear();
      }

      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<String, CycleNote>{});
        return;
      }

      for (var chunkIndex = 0; chunkIndex < chunks.length; chunkIndex++) {
        final chunk = chunks[chunkIndex];
        final query = _notesCollection(uid: user.uid, commandId: commandId)
            .where('cycleKey', whereIn: chunk);

        final sub = query.snapshots().listen(
          (snapshot) {
            perChunk[chunkIndex].clear();
            for (final doc in snapshot.docs) {
              final note = _fromDoc(commandId: commandId, doc: doc);
              perChunk[chunkIndex][note.cycleKey] = note;
            }
            emitMerged();
          },
          onError: (Object error, StackTrace st) {
            if (error is FirebaseException &&
                error.code == 'permission-denied') {
              perChunk[chunkIndex].clear();
              emitMerged();
              return;
            }
            if (!controller.isClosed) {
              controller.addError(error, st);
            }
          },
        );
        chunkSubs.add(sub);
      }
    }

    authSub = _authRepository.authStateChanges().listen(
      (user) => startForUser(user),
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await authSub?.cancel();
      for (final sub in chunkSubs) {
        await sub.cancel();
      }
      chunkSubs.clear();
    };

    return controller.stream;
  }

  @override
  Future<void> saveNote(CycleNote note) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    final docRef = _notesCollection(uid: uid, commandId: note.commandId).doc(note.cycleKey);
    await docRef.set(<String, Object?>{
      'cycleKey': note.cycleKey,
      'content': note.content,
      'updatedAtUtc': Timestamp.fromDate(note.updatedAtUtc.toUtc()),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteNote({
    required String commandId,
    required String cycleKey,
  }) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    await _notesCollection(uid: uid, commandId: commandId).doc(cycleKey).delete();
  }

  @override
  Future<void> deleteAllNotes(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    final collection = _notesCollection(uid: uid, commandId: commandId);
    const batchSize = 500;

    try {
      while (true) {
        final snapshot = await collection.limit(batchSize).get();
        if (snapshot.docs.isEmpty) break;

        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (snapshot.docs.length < batchSize) break;
      }
    } on FirebaseException catch (e, st) {
      // Souvent : règles distantes sans `cycle_notes` (non déployées). On laisse
      // la suppression du commandement se poursuivre ; les notes restent orphelines
      // jusqu’à un déploiement `firebase deploy --only firestore:rules`.
      if (e.code == 'permission-denied') {
        developer.log(
          'deleteAllNotes ignoré (permission-denied). '
          'Vérifier le déploiement de firestore.rules pour cycle_notes. '
          'commandId=$commandId',
          name: 'FirestoreCycleNoteRepository',
          error: e,
          stackTrace: st,
        );
        return;
      }
      rethrow;
    }
  }

  CycleNote _fromDoc({
    required String commandId,
    required QueryDocumentSnapshot<Map<String, Object?>> doc,
  }) {
    final data = doc.data();
    final key = (data['cycleKey'] ?? doc.id).toString();
    final content = (data['content'] ?? '').toString();
    final updatedRaw = data['updatedAtUtc'];
    final updatedAtUtc = _parseUtcDateTime(updatedRaw) ?? DateTime.utc(1970, 1, 1);

    return CycleNote(
      commandId: commandId,
      cycleKey: key,
      content: content,
      updatedAtUtc: updatedAtUtc,
    );
  }

  DateTime? _parseUtcDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toUtc();
  }
}
