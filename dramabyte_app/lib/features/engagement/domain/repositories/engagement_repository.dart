abstract interface class EngagementRepository {
  Future<void> setLike(String episodeId, {required bool liked});
  void recordView(String episodeId);
  Future<void> flushViews();
}
