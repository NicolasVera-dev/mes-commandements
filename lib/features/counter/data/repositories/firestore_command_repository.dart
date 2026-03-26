import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../domain/entities/command.dart';
import '../../domain/repositories/command_repository.dart';

class FirestoreCommandRepository implements CommandRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath;

  FirestoreCommandRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'commands',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  CollectionReference<Map<String, Object?>> get _collection {
    return _firestore.collection(_collectionPath);
  }

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  @override
  Stream<List<Command>> watchAll() {
    if (!_isFirebaseReady) return const Stream.empty();

    return _collection.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => Command.fromMap(
              id: doc.id,
              map: Map<String, Object?>.from(doc.data()),
            ),
          )
          .toList();
    });
  }

  @override
  Future<void> add(Command command) async {
    if (!_isFirebaseReady) return;
    await _collection.doc(command.id).set(command.toMap());
  }

  @override
  Future<void> update(Command command) async {
    if (!_isFirebaseReady) return;
    await _collection.doc(command.id).set(command.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> delete(String commandId) async {
    if (!_isFirebaseReady) return;
    await _collection.doc(commandId).delete();
  }

  @override
  Future<void> incrementProgress(String commandId) async {
    if (!_isFirebaseReady) return;
    final docRef = _collection.doc(commandId);

    await _firestore.runTransaction<void>((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final command = Command.fromMap(
        id: docRef.id,
        map: Map<String, Object?>.from(data),
      );
      final updated = command.incrementProgress();
      // Par défaut merge=false. Sur web, éviter SetOptions explicite aide à réduire
      // les erreurs d'interop.
      tx.set(docRef, updated.toMap());
    });
  }

  @override
  Future<void> resetProgress(String commandId) async {
    if (!_isFirebaseReady) return;
    final docRef = _collection.doc(commandId);

    await _firestore.runTransaction<void>((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final command = Command.fromMap(
        id: docRef.id,
        map: Map<String, Object?>.from(data),
      );
      final updated = command.resetProgress();
      // Par défaut merge=false.
      tx.set(docRef, updated.toMap());
    });
  }
}

