import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/home/data/datasources/home_remote_source.dart';
import 'package:dramabyte_app/features/home/data/models/home_models.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/repositories/home_repository.dart';

final class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote, this._cache);

  static const _key = 'cache_home';
  final HomeRemoteSource _remote;
  final JsonCache _cache;

  @override
  Future<HomeFeed?> cached() async {
    final json = await _cache.read(_key);
    return json == null ? null : HomeFeedModel(json).toEntity();
  }

  @override
  Future<HomeFeed> fetch() async {
    try {
      final model = await _remote.feed();
      await _cache.write(_key, model.json);
      return model.toEntity();
    } on DioException catch (error) {
      AppLogger.error(
        'Home request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      throw const NetworkFailure('Unable to load shows. Try again.');
    }
  }
}
