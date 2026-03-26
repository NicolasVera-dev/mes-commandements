import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/command.dart';
import '../../domain/repositories/command_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FirestoreCommandRepository implements CommandRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreCommandRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository;

  CollectionReference<Map<String, Object?>> _collectionForUser(String uid) {
    return _firestore.collection('users/$uid/commands');
  }

  Future<String?> _currentUserId() async {
    final user = await _authRepository.authStateChanges().first;
    return user?.uid;
  }

  @override
  Stream<List<Command>> watchAll() {
    final controller = StreamController<List<Command>>();

    StreamSubscription<AuthUser?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? commandsSub;

    Future<void> startForUser(AuthUser? user) async {
      await commandsSub?.cancel();
      commandsSub = null;

      if (controller.isClosed) return;

      if (user == null) {
        controller.add(<Command>[]);
        return;
      }

      final collection = _collectionForUser(user.uid);
      commandsSub = collection.snapshots().listen(
        (snapshot) {
          final commands = snapshot.docs
              .map(
                (doc) => Command.fromMap(
                  id: doc.id,
                  map: Map<String, Object?>.from(doc.data()),
                ),
              )
              .toList();
          controller.add(commands);
        },
        onError: controller.addError,
      );
    }

    authSub = _authRepository.authStateChanges().listen(
      (user) => startForUser(user),
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await authSub?.cancel();
      await commandsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> add(Command command) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _collectionForUser(uid).doc(command.id).set(command.toMap());
  }

  @override
  Future<void> update(Command command) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _collectionForUser(uid)
        .doc(command.id)
        .set(command.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> delete(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _collectionForUser(uid).doc(commandId).delete();
  }

  @override
  Future<void> incrementProgress(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final docRef = _collectionForUser(uid).doc(commandId);

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
    final uid = await _currentUserId();
    if (uid == null) return;
    final docRef = _collectionForUser(uid).doc(commandId);

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

