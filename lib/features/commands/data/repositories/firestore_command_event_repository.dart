import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/command_event.dart';
import '../../domain/entities/command_events_period.dart';
import '../../domain/repositories/command_event_repository.dart';

class FirestoreCommandEventRepository implements CommandEventRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreCommandEventRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _eventsCollection({
    required String uid,
    required String commandId,
  }) {
    return _firestore.collection('users/$uid/commands/$commandId/events');
  }

  Future<String?> _currentUserId() async {
    final user = await _authRepository.authStateChanges().first;
    return user?.uid;
  }

  @override
  Stream<List<CommandEvent>> watchEvents(
    String commandId, {
    CommandEventsPeriod? period,
  }) {
    final controller = StreamController<List<CommandEvent>>();
    final resolvedPeriod = period ?? CommandEventsPeriod.currentMonth(DateTime.now().toUtc());

    StreamSubscription<AuthUser?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? eventsSub;

    Future<void> startForUser(AuthUser? user) async {
      await eventsSub?.cancel();
      eventsSub = null;

      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<CommandEvent>[]);
        return;
      }

      final query = _eventsCollection(uid: user.uid, commandId: commandId)
          .where(
            'actionAtUtc',
            isGreaterThanOrEqualTo: Timestamp.fromDate(resolvedPeriod.startUtc.toUtc()),
          )
          .where(
            'actionAtUtc',
            isLessThan: Timestamp.fromDate(resolvedPeriod.endUtc.toUtc()),
          )
          .orderBy('actionAtUtc', descending: true);

      eventsSub = query.snapshots().listen(
        (snapshot) {
          final events = snapshot.docs.map((doc) {
            final map = Map<String, Object?>.from(doc.data());
            return _fromFirestoreMap(map);
          }).toList(growable: false);
          controller.add(events);
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
      await eventsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<CommandEvent>> watchEventsFrom(
    String commandId, {
    required DateTime startUtcInclusive,
  }) {
    final controller = StreamController<List<CommandEvent>>();
    final start = startUtcInclusive.toUtc();

    StreamSubscription<AuthUser?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? eventsSub;

    Future<void> startForUser(AuthUser? user) async {
      await eventsSub?.cancel();
      eventsSub = null;

      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<CommandEvent>[]);
        return;
      }

      final query = _eventsCollection(uid: user.uid, commandId: commandId)
          .where(
            'actionAtUtc',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start),
          )
          .orderBy('actionAtUtc', descending: false);

      eventsSub = query.snapshots().listen(
        (snapshot) {
          final events = snapshot.docs.map((doc) {
            final map = Map<String, Object?>.from(doc.data());
            return _fromFirestoreMap(map);
          }).toList(growable: false);
          controller.add(events);
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
      await eventsSub?.cancel();
    };

    return controller.stream;
  }

  @override
  void addEventFireAndForget({
    required String commandId,
    required CommandEvent event,
  }) {
    unawaited(_addEvent(commandId: commandId, event: event));
  }

  Future<void> _addEvent({
    required String commandId,
    required CommandEvent event,
  }) async {
    try {
      final uid = await _currentUserId();
      if (uid == null) return;
      await _eventsCollection(uid: uid, commandId: commandId).add(
        _toFirestoreMap(event),
      );
    } catch (error, st) {
      // Fire-and-forget intentionnel: log uniquement.
      developer.log(
        'Erreur ajout event Firestore ($commandId): $error',
        name: 'FirestoreCommandEventRepository',
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteAllEvents(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return;

    final collection = _eventsCollection(uid: uid, commandId: commandId);
    const batchSize = 500;

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
  }

  @override
  Future<DateTime?> firstEventAtUtc(String commandId) async {
    final uid = await _currentUserId();
    if (uid == null) return null;

    final snapshot = await _eventsCollection(uid: uid, commandId: commandId)
        .orderBy('actionAtUtc')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    return _parseUtcDateTime(data['actionAtUtc']);
  }

  Map<String, Object?> _toFirestoreMap(CommandEvent event) {
    final atUtc = event.actionAtUtc.toUtc();
    return <String, Object?>{
      'type': event.type.name,
      'actionAtUtc': Timestamp.fromDate(atUtc),
      'progressAfterAction': event.progressAfterAction,
      'targetAtAction': event.targetAtAction,
      'cycleKey': event.cycleKey,
    };
  }

  CommandEvent _fromFirestoreMap(Map<String, Object?> map) {
    final typeRaw = (map['type'] ?? '').toString();
    final type = CommandEventType.values.firstWhere(
      (t) => t.name == typeRaw,
      orElse: () => CommandEventType.increment,
    );

    final actionAtUtc = _parseUtcDateTime(map['actionAtUtc']) ?? DateTime.utc(1970, 1, 1);
    final progress = _parseInt(map['progressAfterAction']);
    final target = _parseInt(map['targetAtAction']);
    final cycleKey = _normalizeCycleKey((map['cycleKey'] ?? '').toString());

    return CommandEvent(
      type: type,
      actionAtUtc: actionAtUtc,
      progressAfterAction: progress,
      targetAtAction: target,
      cycleKey: cycleKey,
    );
  }

  DateTime? _parseUtcDateTime(Object? raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate().toUtc();
    if (raw is DateTime) return raw.toUtc();
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toUtc();
  }

  int _parseInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  String _normalizeCycleKey(String raw) {
    final key = raw.trim();
    if (key.isEmpty) return key;
    final weeklyMatch = RegExp(r'^(\d{4})-[Ww](\d{2})$').firstMatch(key);
    if (weeklyMatch != null) {
      return '${weeklyMatch.group(1)}-S${weeklyMatch.group(2)}';
    }
    return key;
  }
}
