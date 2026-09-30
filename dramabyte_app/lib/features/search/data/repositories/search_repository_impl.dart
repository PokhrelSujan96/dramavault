import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/search/data/datasources/search_local_source.dart';
import 'package:dramabyte_app/features/search/data/datasources/search_remote_source.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/domain/repositories/search_repository.dart';

final class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._remote, this._local);

  final SearchRemoteSource _remote;
  final SearchLocalSource _local;

  @override
  Future<List<SearchResult>> search(String query) async {
    try {
      final models = await _remote.search(query);
      return [for (final model in models) ?model.toEntity()];
    } on DioException catch (error) {
      AppLogger.error(
        'Search request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      throw const NetworkFailure('Unable to search right now. Try again.');
    }
  }

  @override
  Future<List<String>> recents() async => _local.recents();

  @override
  Future<void> saveRecent(String query) => _local.save(query);

  @override
  Future<void> removeRecent(String query) => _local.remove(query);

  @override
  Future<void> clearRecents() => _local.clear();
}
