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

  /// Supprime relapses + day_notes puis le document résistance.
  Future<void> _deleteResistanceDoc(
    DocumentReference<Map<String, Object?>> resistanceRef,
  ) async {
    await _purgeSubcollection(resistanceRef.collection('relapses'));
    await _purgeSubcollection(resistanceRef.collection('day_notes'));
    await resistanceRef.delete();
  }

  @override
  Future<void> deleteAllUserData({
    required String uid,
  }) async {
    final commandsCollection = _firestore.collection('users/$uid/commands');
    final commandsSnapshot = await commandsCollection.get();

    for (final commandDoc in commandsSnapshot.docs) {
      await _purgeSubcollection(commandDoc.reference.collection('events'));
      await _purgeSubcollection(commandDoc.reference.collection('cycle_notes'));
      await commandDoc.reference.delete();
    }

    final resistancesCollection = _firestore.collection('users/$uid/resistances');
    final resistancesSnapshot = await resistancesCollection.get();
    for (final doc in resistancesSnapshot.docs) {
      await _deleteResistanceDoc(doc.reference);
    }
  }
}
