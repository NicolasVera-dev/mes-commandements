abstract class AccountDataCleanupRepository {
  Future<void> deleteAllUserData({
    required String uid,
  });
}
