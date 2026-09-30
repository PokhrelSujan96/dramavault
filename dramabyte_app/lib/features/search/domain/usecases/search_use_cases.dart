import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/domain/repositories/search_repository.dart';

final class SearchSeries implements UseCase<List<SearchResult>, String> {
  SearchSeries(this._repository);

  final SearchRepository _repository;

  @override
  Future<List<SearchResult>> call(String params) => _repository.search(params);
}

final class GetRecentSearches implements UseCase<List<String>, NoParams> {
  GetRecentSearches(this._repository);

  final SearchRepository _repository;

  @override
  Future<List<String>> call(NoParams params) => _repository.recents();
}

final class SaveRecentSearch implements UseCase<void, String> {
  SaveRecentSearch(this._repository);

  final SearchRepository _repository;

  @override
  Future<void> call(String params) => _repository.saveRecent(params);
}

final class RemoveRecentSearch implements UseCase<void, String> {
  RemoveRecentSearch(this._repository);

  final SearchRepository _repository;

  @override
  Future<void> call(String params) => _repository.removeRecent(params);
}

final class ClearRecentSearches implements UseCase<void, NoParams> {
  ClearRecentSearches(this._repository);

  final SearchRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.clearRecents();
}
