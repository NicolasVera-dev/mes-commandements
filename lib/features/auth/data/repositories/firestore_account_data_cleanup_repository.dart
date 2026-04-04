import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/account_data_cleanup_repository.dart';

class FirestoreAccountDataCleanupRepository
    implements AccountDataCleanupRepository {
  final FirebaseFirestore _firestore;

  FirestoreAccountDataCleanupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

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

  @override
  Future<void> deleteAllUserData({
    required String uid,
  }) async {
    final commandsCollection = _firestore.collection('users/$uid/commands');
    final commandsSnapshot = await commandsCollection.get();
    if (commandsSnapshot.docs.isEmpty) return;

    for (final commandDoc in commandsSnapshot.docs) {
      await _purgeSubcollection(commandDoc.reference.collection('events'));
      await _purgeSubcollection(commandDoc.reference.collection('cycle_notes'));
      await commandDoc.reference.delete();
    }
  }
}
