import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/auto_reset_report.dart';
import '../../domain/entities/command.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/entities/command_position_update.dart';
import '../../domain/repositories/command_event_repository.dart';
import '../../domain/repositories/command_repository.dart';
import '../../domain/repositories/cycle_note_repository.dart';
import '../../domain/usecases/plan_backfill_cycle_completion_usecase.dart';
import '../../domain/usecases/plan_edit_cycle_event_cleanup_usecase.dart';
import '../../domain/usecases/plan_remove_cycle_completion_usecase.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class FirestoreCommandRepository implements CommandRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;
  final CommandEventRepository? _eventRepository;
  final CycleNoteRepository? _cycleNoteRepository;

  FirestoreCommandRepository({
    required AuthRepository authRepository,
    CommandEventRepository? eventRepository,
    CycleNoteRepository? cycleNoteRepository,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _authRepository = authRepository,
       _eventRepository = eventRepository,
       _cycleNoteRepository = cycleNoteRepository;

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
      commandsSub = collection.snapshots().listen((snapshot) {
        final commands = snapshot.docs
            .map(
              (doc) => Command.fromMap(
                id: doc.id,
                map: Map<String, Object?>.from(doc.data()),
              ),
            )
            .toList();
        controller.add(commands);
      }, onError: controller.addError);
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
    final dueDocs = snapshot.docs
        .where((doc) {
          final command = Command.fromMap(
            id: doc.id,
            map: Map<String, Object?>.from(doc.data()),
          );
          return command.shouldAutoReset(nowUtc);
        })
        .toList(growable: false);

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
        developer.log(
          'Erreur reset auto atomique (${command.id}): $error',
          name: 'FirestoreCommandRepository',
          stackTrace: st,
        );
      }
    }

    return AutoResetReport(total: updatedCount, byFrequency: byFrequency);
  }

  @override
  Future<void> add(Command command) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final collection = _collectionForUser(uid);
    final snapshot = await collection
        .orderBy('position', descending: true)
        .limit(1)
        .get();
    final maxPosition = snapshot.docs.isEmpty
        ? -1
        : Command.fromMap(
            id: snapshot.docs.first.id,
            map: Map<String, Object?>.from(snapshot.docs.first.data()),
          ).position;
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
    final commandRef = _collectionForUser(uid).doc(command.id);
    final beforeSnapshot = await commandRef.get();
    final beforeData = beforeSnapshot.data();
    if (beforeData == null) return;

    final before = Command.fromMap(
      id: command.id,
      map: Map<String, Object?>.from(beforeData),
    );
    final cleanupScope = const PlanEditCycleEventCleanupUseCase().execute(
      before: before,
      after: command,
    );

    if (cleanupScope == EditEventCleanupScope.none) {
      await commandRef.update(_commandEditableFields(command));
      return;
    }

    try {
      final eventsCollection = _eventsCollectionForCommand(
        uid: uid,
        commandId: command.id,
      );
      final docsToDelete = <QueryDocumentSnapshot<Map<String, Object?>>>[];

      if (cleanupScope == EditEventCleanupScope.currentCycleOnly) {
        final candidateCycleKeys = _cycleKeyCandidates(
          command: before,
          atUtc: DateTime.now().toUtc(),
        );
        final seenEventIds = <String>{};
        for (final cycleKey in candidateCycleKeys) {
          final cycleEventsSnapshot = await eventsCollection
              .where('cycleKey', isEqualTo: cycleKey)
              .where(
                'type',
                whereIn: <String>[
                  CommandEventType.complete.name,
                  CommandEventType.increment.name,
                ],
              )
              .get();
          for (final doc in cycleEventsSnapshot.docs) {
            if (seenEventIds.add(doc.id)) {
              docsToDelete.add(doc);
            }
          }
        }
      } else {
        final allEventsSnapshot = await eventsCollection.limit(500).get();
        if (allEventsSnapshot.docs.length >= 500) {
          throw StateError(
            'Édition impossible en un batch atomique: trop d’événements à purger.',
          );
        }
        docsToDelete.addAll(allEventsSnapshot.docs);
      }

      final batch = _firestore.batch();
      for (final eventDoc in docsToDelete) {
        batch.delete(eventDoc.reference);
      }

      if (cleanupScope == EditEventCleanupScope.currentCycleOnly) {
        final eventAtUtc = DateTime.now().toUtc();
        final rebuiltEvents = _eventsForCommandStateAfterEdit(
          command: command,
          eventAtUtc: eventAtUtc,
        );
        for (final event in rebuiltEvents) {
          batch.set(eventsCollection.doc(), _eventToMap(event));
        }
      }

      // Purge des événements atomique AVANT sauvegarde (même batch commit).
      batch.update(commandRef, _commandEditableFields(command));
      await batch.commit();
    } catch (error, st) {
      developer.log(
        'Erreur purge atomique lors de la mise à jour (${command.id}): $error',
        name: 'FirestoreCommandRepository',
        stackTrace: st,
      );
      rethrow;
    }
  }

  @override
  Future<void> delete(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    await _cycleNoteRepository?.deleteAllNotes(commandId);

    final commandRef = _collectionForUser(uid).doc(commandId);
    final eventsCollection = commandRef.collection('events');
    final eventsSnapshot = await eventsCollection.limit(500).get();

    // Firestore limite un batch à 500 opérations.
    // On réserve 1 opération pour le document commandement.
    if (eventsSnapshot.docs.length >= 500) {
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
      tx.update(docRef, <String, Object?>{'progress': updated.progress});
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

  @override
  Future<void> completePastCycle({
    required String commandId,
    required String cycleKey,
  }) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final commandRef = _collectionForUser(uid).doc(commandId);
    final snapshot = await commandRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data();
    if (data == null) return;
    final command = Command.fromMap(
      id: commandRef.id,
      map: Map<String, Object?>.from(data),
    );

    final now = DateTime.now().toUtc();
    final requestedCycleCandidates = _cycleKeyCandidatesFromRequested(
      frequency: command.frequency,
      cycleKey: cycleKey,
    );
    final eventsCollection = _eventsCollectionForCommand(
      uid: uid,
      commandId: command.id,
    );
    final completeEventsForCycle =
        <QueryDocumentSnapshot<Map<String, Object?>>>[];
    for (final cycleCandidate in requestedCycleCandidates) {
      final snapshot = await eventsCollection
          .where('cycleKey', isEqualTo: cycleCandidate)
          .where('type', isEqualTo: CommandEventType.complete.name)
          .limit(1)
          .get();
      completeEventsForCycle.addAll(snapshot.docs);
    }
    final isAlreadyCompleted = completeEventsForCycle.isNotEmpty;

    final plan = const PlanBackfillCycleCompletionUseCase().execute(
      frequency: command.frequency,
      cycleKey: cycleKey,
      isAlreadyCompleted: isAlreadyCompleted,
      nowUtc: now,
    );
    final completeEvent = CommandEvent(
      type: CommandEventType.complete,
      actionAtUtc: plan.actionAtUtc,
      progressAfterAction: command.target,
      targetAtAction: command.target,
      cycleKey: plan.cycleKey,
    );
    await eventsCollection.add(_eventToMap(completeEvent));
  }

  @override
  Future<void> uncompletePastCycle({
    required String commandId,
    required String cycleKey,
  }) async {
    final uid = await _currentUserId();
    if (uid == null) return;
    final commandRef = _collectionForUser(uid).doc(commandId);
    final snapshot = await commandRef.get();
    if (!snapshot.exists) return;
    final data = snapshot.data();
    if (data == null) return;
    final command = Command.fromMap(
      id: commandRef.id,
      map: Map<String, Object?>.from(data),
    );

    final now = DateTime.now().toUtc();
    final requestedCycleCandidates = _cycleKeyCandidatesFromRequested(
      frequency: command.frequency,
      cycleKey: cycleKey,
    );
    final eventsCollection = _eventsCollectionForCommand(
      uid: uid,
      commandId: command.id,
    );
    final completeEventsForCycle =
        <QueryDocumentSnapshot<Map<String, Object?>>>[];
    final seenDocIds = <String>{};
    for (final cycleCandidate in requestedCycleCandidates) {
      final snapshot = await eventsCollection
          .where('cycleKey', isEqualTo: cycleCandidate)
          .where('type', isEqualTo: CommandEventType.complete.name)
          .get();
      for (final doc in snapshot.docs) {
        if (seenDocIds.add(doc.id)) {
          completeEventsForCycle.add(doc);
        }
      }
    }

    final plan = const PlanRemoveCycleCompletionUseCase().execute(
      frequency: command.frequency,
      cycleKey: cycleKey,
      isAlreadyCompleted: completeEventsForCycle.isNotEmpty,
      nowUtc: now,
    );
    final normalizedCandidates = _cycleKeyCandidatesFromRequested(
      frequency: command.frequency,
      cycleKey: plan.cycleKey,
    );

    final batch = _firestore.batch();
    for (final eventDoc in completeEventsForCycle) {
      final eventData = eventDoc.data();
      final key = (eventData['cycleKey'] ?? '').toString().trim();
      if (normalizedCandidates.contains(key)) {
        batch.delete(eventDoc.reference);
      }
    }
    await batch.commit();
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
    final candidateCycleKeys = _cycleKeyCandidates(
      command: commandBeforeReset,
      atUtc: eventAtUtc,
    );
    final cycleEventDocs = <QueryDocumentSnapshot<Map<String, Object?>>>[];
    final seenEventIds = <String>{};
    for (final cycleKey in candidateCycleKeys) {
      final cycleEventsSnapshot = await eventsCollection
          .where('cycleKey', isEqualTo: cycleKey)
          .where(
            'type',
            whereIn: <String>[
              CommandEventType.complete.name,
              CommandEventType.increment.name,
            ],
          )
          .get();
      for (final doc in cycleEventsSnapshot.docs) {
        if (seenEventIds.add(doc.id)) {
          cycleEventDocs.add(doc);
        }
      }
    }

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

    for (final eventDoc in cycleEventDocs) {
      batch.delete(eventDoc.reference);
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

  List<String> _cycleKeyCandidates({
    required Command command,
    required DateTime atUtc,
  }) {
    final key = command.cycleKeyAt(atUtc);
    if (command.frequency != Frequency.weekly) {
      return <String>[key];
    }
    final legacy = key.contains('-S') ? key.replaceFirst('-S', '-W') : key;
    if (legacy == key) {
      return <String>[key];
    }
    return <String>[key, legacy];
  }

  List<String> _cycleKeyCandidatesFromRequested({
    required Frequency frequency,
    required String cycleKey,
  }) {
    final raw = cycleKey.trim();
    if (raw.isEmpty || frequency != Frequency.weekly) {
      return <String>[raw];
    }
    final normalizedMatch = RegExp(r'^(\d{4})-[SW](\d{2})$').firstMatch(raw);
    if (normalizedMatch == null) {
      return <String>[raw];
    }
    final normalized =
        '${normalizedMatch.group(1)}-S${normalizedMatch.group(2)}';
    final legacy = '${normalizedMatch.group(1)}-W${normalizedMatch.group(2)}';
    if (normalized == legacy) return <String>[normalized];
    return <String>[normalized, legacy];
  }

  List<CommandEvent> _eventsForCommandStateAfterEdit({
    required Command command,
    required DateTime eventAtUtc,
  }) {
    if (command.progress <= 0) return const <CommandEvent>[];
    final increment = command.toEvent(
      type: CommandEventType.increment,
      actionAtUtc: eventAtUtc,
    );
    if (!command.isCompleted()) {
      return <CommandEvent>[increment];
    }
    final complete = command.toEvent(
      type: CommandEventType.complete,
      actionAtUtc: eventAtUtc,
    );
    return <CommandEvent>[increment, complete];
  }
}
