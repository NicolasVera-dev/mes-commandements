import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/resistance_relapse.dart';
import '../../domain/repositories/resistance_relapse_repository.dart';

class FirestoreResistanceRelapseRepository implements ResistanceRelapseRepository {
  final FirebaseFirestore _firestore;
  final AuthRepository _authRepository;

  FirestoreResistanceRelapseRepository({
    required AuthRepository authRepository,
    FirebaseFirestore? firestore,
  })  : _authRepository = authRepository,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, Object?>> _relapsesCollection({
    required String uid,
    required String resistanceId,
  }) {
    return _firestore.collection('users/$uid/resistances/$resistanceId/relapses');
  }

  @override
  Stream<List<ResistanceRelapse>> watchRelapses(String resistanceId) {
    final controller = StreamController<List<ResistanceRelapse>>();
    StreamSubscription<AuthUser?>? authSub;
    StreamSubscription<QuerySnapshot<Map<String, Object?>>>? sub;

    Future<void> startForUser(AuthUser? user) async {
      await sub?.cancel();
      sub = null;
      if (controller.isClosed) return;
      if (user == null) {
        controller.add(<ResistanceRelapse>[]);
        return;
      }

      final query = _relapsesCollection(uid: user.uid, resistanceId: resistanceId)
          .orderBy('relapsedAtUtc', descending: true);

      sub = query.snapshots().listen(
        (snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => ResistanceRelapse.fromMap(
                  id: doc.id,
                  resistanceId: resistanceId,
                  map: Map<String, Object?>.from(doc.data()),
                ),
              )
              .toList(growable: false);
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
}
