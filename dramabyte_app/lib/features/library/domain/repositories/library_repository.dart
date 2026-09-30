import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';

abstract interface class LibraryRepository {
  Future<List<LibraryItem>?> cached(String userId);
  Future<List<LibraryItem>> fetch(String userId);
  Stream<void> changes(String userId);
  Future<void> add(String seriesId);
  Future<void> remove(String seriesId);
}
