import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_page.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryItem>?> cached(String userId);
  Future<List<HistoryItem>> recent(String userId);
  Stream<void> changes(String userId);
  Future<HistoryPage> page(String? cursor);
  Future<void> record(String episodeId, int seconds);
  Future<void> remove(String? episodeId);
}
