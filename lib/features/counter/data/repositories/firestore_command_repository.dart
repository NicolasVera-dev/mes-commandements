import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/auto_reset_report.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_position_update.dart';
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

  Map<String, Object?> _commandEditableFields(Command command) {
    return <String, Object?>{
      'title': command.title,
      'description': command.description,
      'target': command.target,
      'progress': command.progress,
      'frequency': command.frequency.name,
      'emoji': command.emoji,
      'accentColorValue': command.accentColorValue,
      'position': command.position,
      'tags': command.tags,
    };
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
  Future<AutoResetReport> applyPendingAutoResets(DateTime now) async {
    final uid = await _currentUserId();
    if (uid == null) return const AutoResetReport.empty();

    final collection = _collectionForUser(uid);
    final snapshot = await collection.get();
    if (snapshot.docs.isEmpty) return const AutoResetReport.empty();

    final nowUtc = now.toUtc();
    final dueDocs = snapshot.docs.where((doc) {
      final command = Command.fromMap(
        id: doc.id,
        map: Map<String, Object?>.from(doc.data()),
      );
      return command.shouldAutoReset(nowUtc);
    }).toList(growable: false);

    if (dueDocs.isEmpty) return const AutoResetReport.empty();

    var updatedCount = 0;
    final byFrequency = <Frequency, int>{};
    const maxBatchSize = 500;

    for (var i = 0; i < dueDocs.length; i += maxBatchSize) {
      final end = (i + maxBatchSize > dueDocs.length)
          ? dueDocs.length
          : i + maxBatchSize;
      final chunk = dueDocs.sublist(i, end);

      final batch = _firestore.batch();
      for (final doc in chunk) {
        final command = Command.fromMap(
          id: doc.id,
          map: Map<String, Object?>.from(doc.data()),
        );
        final resetCommand = command.applyAutoResetIfNeeded(nowUtc);
        if (resetCommand == command) continue;
        batch.update(doc.reference, <String, Object?>{
          'progress': resetCommand.progress,
          'lastResetAt': resetCommand.lastResetAt?.toIso8601String(),
        });
        updatedCount++;
        byFrequency[command.frequency] =
            (byFrequency[command.frequency] ?? 0) + 1;
      }
      await batch.commit();
    }

    return AutoResetReport(total: updatedCount, byFrequency: byFrequency);
  }

  @override
  Future<void> add(Command command) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final collection = _collectionForUser(uid);
    final snapshot = await collection.get();
    var maxPosition = -1;
    for (final doc in snapshot.docs) {
      final existing = Command.fromMap(
        id: doc.id,
        map: Map<String, Object?>.from(doc.data()),
      );
      if (existing.position > maxPosition) {
        maxPosition = existing.position;
      }
    }
    final withPosition = command.copyWith(position: maxPosition + 1);
    await collection.doc(command.id).set(withPosition.toMap());
  }

  @override
  Future<void> updatePositions(List<CommandPositionUpdate> updates) async {
    final uid = await _currentUserId();
    if (uid == null || updates.isEmpty) return;
    final collection = _collectionForUser(uid);
    const maxBatchSize = 500;

    for (var i = 0; i < updates.length; i += maxBatchSize) {
      final end = (i + maxBatchSize > updates.length)
          ? updates.length
          : i + maxBatchSize;
      final chunk = updates.sublist(i, end);
      final batch = _firestore.batch();
      for (final update in chunk) {
        final ref = collection.doc(update.commandId);
        batch.update(ref, <String, Object?>{'position': update.position});
      }
      await batch.commit();
    }
  }

  @override
  Future<void> update(Command command) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    await _collectionForUser(uid)
        .doc(command.id)
        .update(_commandEditableFields(command));
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
      tx.update(docRef, <String, Object?>{
        'progress': updated.progress,
      });
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
      tx.update(docRef, <String, Object?>{
        'progress': updated.progress,
        'lastResetAt': updated.lastResetAt?.toIso8601String(),
      });
    });
  }
}

