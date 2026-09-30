import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';

abstract interface class SearchRepository {
  Future<List<SearchResult>> search(String query);
  Future<List<String>> recents();
  Future<void> saveRecent(String query);
  Future<void> removeRecent(String query);
  Future<void> clearRecents();
}
