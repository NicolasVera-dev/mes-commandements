import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/auto_reset_report.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/entities/command_position_update.dart';
import '../../domain/repositories/command_event_repository.dart';
import '../../domain/repositories/command_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FirestoreCommandRepository implements CommandRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;
  final CommandEventRepository? _eventRepository;

  FirestoreCommandRepository({
    required AuthRepository authRepository,
    CommandEventRepository? eventRepository,
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _authRepository = authRepository,
        _eventRepository = eventRepository;

  CollectionReference<Map<String, Object?>> _collectionForUser(String uid) {
    return _firestore.collection('users/$uid/commands');
  }

  CollectionReference<Map<String, Object?>> _eventsCollectionForCommand({
    required String uid,
    required String commandId,
  }) {
    return _firestore.collection('users/$uid/commands/$commandId/events');
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
    for (final doc in dueDocs) {
      final command = Command.fromMap(
        id: doc.id,
        map: Map<String, Object?>.from(doc.data()),
      );
      final resetCommand = command.applyAutoResetIfNeeded(nowUtc);
      if (resetCommand == command) continue;
      try {
        await _applyResetBatch(
          uid: uid,
          commandBeforeReset: command,
          commandAfterReset: resetCommand,
          resetType: CommandEventType.resetAuto,
          eventAtUtc: nowUtc,
        );
        updatedCount++;
        byFrequency[command.frequency] =
            (byFrequency[command.frequency] ?? 0) + 1;
      } catch (error, st) {
        debugPrint('Erreur reset auto atomique (${command.id}): $error');
        debugPrint('$st');
      }
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
    final withPosition = command.copyWith(
      position: maxPosition + 1,
      createdAt: command.createdAt ?? DateTime.now().toUtc(),
    );
    final payload = withPosition.toMap();
    payload['createdAt'] = Timestamp.fromDate(withPosition.createdAt!.toUtc());
    await collection.doc(command.id).set(payload);
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

    final commandRef = _collectionForUser(uid).doc(commandId);
    final eventsSnapshot = await commandRef.collection('events').get();

    // Firestore limite un batch à 500 opérations.
    // On réserve 1 opération pour le document commandement.
    if (eventsSnapshot.docs.length > 499) {
      throw StateError(
        'Suppression impossible en un batch atomique: trop d’événements à supprimer.',
      );
    }

    final batch = _firestore.batch();
    for (final eventDoc in eventsSnapshot.docs) {
      batch.delete(eventDoc.reference);
    }
    batch.delete(commandRef);
    await batch.commit();
  }

  @override
  Future<void> incrementProgress(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final docRef = _collectionForUser(uid).doc(commandId);
    Command? updatedAfterIncrement;
    Command? completedAtIncrement;
    final eventAt = DateTime.now().toUtc();

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
      updatedAfterIncrement = updated;
      if (!command.isCompleted() && updated.isCompleted()) {
        completedAtIncrement = updated;
      }
      tx.update(docRef, <String, Object?>{
        'progress': updated.progress,
      });
    });

    if (updatedAfterIncrement != null) {
      _eventRepository?.addEventFireAndForget(
        commandId: commandId,
        event: updatedAfterIncrement!.toEvent(
          type: CommandEventType.increment,
          actionAtUtc: eventAt,
        ),
      );
    }

    if (completedAtIncrement != null) {
      _eventRepository?.addEventFireAndForget(
        commandId: commandId,
        event: completedAtIncrement!.toEvent(
          type: CommandEventType.complete,
          actionAtUtc: eventAt,
        ),
      );
    }
  }

  @override
  Future<void> resetProgress(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final docRef = _collectionForUser(uid).doc(commandId);
    final eventAt = DateTime.now().toUtc();
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data();
    if (data == null) return;
    final command = Command.fromMap(
      id: docRef.id,
      map: Map<String, Object?>.from(data),
    );
    final updated = command.resetProgress(resetAt: eventAt);
    await _applyResetBatch(
      uid: uid,
      commandBeforeReset: command,
      commandAfterReset: updated,
      resetType: CommandEventType.resetManual,
      eventAtUtc: eventAt,
    );
  }

  Future<void> _applyResetBatch({
    required String uid,
    required Command commandBeforeReset,
    required Command commandAfterReset,
    required CommandEventType resetType,
    required DateTime eventAtUtc,
  }) async {
    final commandRef = _collectionForUser(uid).doc(commandBeforeReset.id);
    final eventsCollection = _eventsCollectionForCommand(
      uid: uid,
      commandId: commandBeforeReset.id,
    );
    final currentCycleKey = commandBeforeReset.cycleKeyAt(eventAtUtc);

    final cycleEventsSnapshot = await eventsCollection
        .where('cycleKey', isEqualTo: currentCycleKey)
        .get();

    final batch = _firestore.batch();
    batch.update(commandRef, <String, Object?>{
      'progress': commandAfterReset.progress,
      'lastResetAt': commandAfterReset.lastResetAt?.toIso8601String(),
    });

    final resetEvent = commandAfterReset.toEvent(
      type: resetType,
      actionAtUtc: eventAtUtc,
    );
    batch.set(eventsCollection.doc(), _eventToMap(resetEvent));

    for (final eventDoc in cycleEventsSnapshot.docs) {
      final map = eventDoc.data();
      final type = (map['type'] ?? '').toString();
      if (type == CommandEventType.complete.name ||
          type == CommandEventType.increment.name) {
        batch.delete(eventDoc.reference);
      }
    }

    await batch.commit();
  }

  Map<String, Object?> _eventToMap(CommandEvent event) {
    return <String, Object?>{
      'type': event.type.name,
      'actionAtUtc': Timestamp.fromDate(event.actionAtUtc.toUtc()),
      'progressAfterAction': event.progressAfterAction,
      'targetAtAction': event.targetAtAction,
      'cycleKey': event.cycleKey,
    };
  }
}

