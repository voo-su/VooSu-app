abstract interface class AccountRepository {
  Future<List<int>> getFile(int fileId);

  void cacheFileBytes(int fileId, List<int> bytes);
}
