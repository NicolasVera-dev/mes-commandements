import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/repositories/account_data_cleanup_repository.dart';

class FirestoreAccountDataCleanupRepository
    implements AccountDataCleanupRepository {
  final FirebaseFirestore _firestore;

  FirestoreAccountDataCleanupRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> deleteAllUserData({
    required String uid,
  }) async {
    final commandsCollection = _firestore.collection('users/$uid/commands');
    final commandsSnapshot = await commandsCollection.get();
    if (commandsSnapshot.docs.isEmpty) return;

    const maxBatchOps = 500;
    const eventsLimitPerBatch = maxBatchOps - 1;

    for (final commandDoc in commandsSnapshot.docs) {
      while (true) {
        final eventsSnapshot = await commandDoc.reference
            .collection('events')
            .limit(eventsLimitPerBatch)
            .get();
        final eventDocs = eventsSnapshot.docs;

        if (eventDocs.isEmpty) {
          await commandDoc.reference.delete();
          break;
        }
        final batch = _firestore.batch();
        for (final eventDoc in eventDocs) {
          batch.delete(eventDoc.reference);
        }
        if (eventDocs.length < eventsLimitPerBatch) {
          batch.delete(commandDoc.reference);
        }
        await batch.commit();
        if (eventDocs.length < eventsLimitPerBatch) {
          break;
        }
      }
    }
  }
}
