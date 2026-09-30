import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/domain/repositories/library_repository.dart';

final class GetCachedLibrary implements UseCase<List<LibraryItem>?, String> {
  GetCachedLibrary(this._repository);

  final LibraryRepository _repository;

  @override
  Future<List<LibraryItem>?> call(String params) => _repository.cached(params);
}

final class GetLibrary implements UseCase<List<LibraryItem>, String> {
  GetLibrary(this._repository);

  final LibraryRepository _repository;

  @override
  Future<List<LibraryItem>> call(String params) => _repository.fetch(params);
}

final class WatchLibraryChanges {
  WatchLibraryChanges(this._repository);

  final LibraryRepository _repository;

  Stream<void> call(String userId) => _repository.changes(userId);
}

final class AddToLibrary implements UseCase<void, String> {
  AddToLibrary(this._repository);

  final LibraryRepository _repository;

  @override
  Future<void> call(String params) => _repository.add(params);
}

final class RemoveFromLibrary implements UseCase<void, String> {
  RemoveFromLibrary(this._repository);

  final LibraryRepository _repository;

  @override
  Future<void> call(String params) => _repository.remove(params);
}
