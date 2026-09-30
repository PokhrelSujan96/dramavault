import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/data/datasources/series_remote_source.dart';
import 'package:dramabyte_app/features/series/data/models/series_details_model.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/domain/repositories/series_repository.dart';

final class SeriesRepositoryImpl implements SeriesRepository {
  SeriesRepositoryImpl(this._remote, this._cache);

  final SeriesRemoteSource _remote;
  final JsonCache _cache;

  String _key(String seriesId) => 'cache_series_$seriesId';

  @override
  Future<SeriesDetails?> cached(String seriesId) async {
    final json = await _cache.read(_key(seriesId));
    return json == null ? null : SeriesDetailsModel(json).toEntity();
  }

  @override
  Future<SeriesDetails> fetch(String seriesId) => _guard(() async {
    final model = await _remote.details(seriesId);
    final details = model.toEntity();
    if (details == null) throw const ValidationFailure('Series not found.');
    await _cache.write(_key(seriesId), model.json);
    return details;
  });

  @override
  Future<List<Reel>> playlist(String seriesId) => _guard(
    () async => [
      for (final item in await _remote.playlist(seriesId)) ?item.toEntity(),
    ],
  );

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'Series request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      final status = error.response?.statusCode ?? 0;
      if (status >= 400 && status < 500) {
        throw const ValidationFailure('This series is not available.');
      }
      throw const NetworkFailure('Unable to load this series. Try again.');
    }
  }
}
