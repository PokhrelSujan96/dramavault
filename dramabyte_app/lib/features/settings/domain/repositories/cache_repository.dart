abstract interface class CacheRepository {
  Future<int> size();
  Future<void> clear();
}
