import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/features/library/data/datasources/library_remote_source.dart';
import 'package:dramabyte_app/features/library/data/models/library_item_model.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/domain/repositories/library_repository.dart';

final class LibraryRepositoryImpl implements LibraryRepository {
  LibraryRepositoryImpl(this._remote, this._cache, this._realtime);

  final LibraryRemoteSource _remote;
  final JsonCache _cache;
  final RealtimeService _realtime;

  String _key(String userId) => 'cache_library_$userId';

  @override
  Future<List<LibraryItem>?> cached(String userId) async {
    final items = (await _cache.read(_key(userId)))?['items'];
    if (items is! List) return null;
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) ?LibraryItemModel(item).toEntity(),
    ];
  }

  @override
  Future<List<LibraryItem>> fetch(String userId) => _guard(() async {
    final models = await _remote.list();
    await _cache.write(_key(userId), {
      'items': [for (final model in models) model.json],
    });
    return [for (final model in models) ?model.toEntity()];
  });

  @override
  Stream<void> changes(String userId) =>
      _realtime.changes('library_items', column: 'user_id', userId: userId);

  @override
  Future<void> add(String seriesId) => _guard(() => _remote.add(seriesId));

  @override
  Future<void> remove(String seriesId) =>
      _guard(() => _remote.remove(seriesId));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'Library request failed: ${error.type.name} '
        'status=${error.response?.statusCode} body=${error.response?.data}',
        error: error,
      );
      final data = error.response?.data;
      final status = error.response?.statusCode ?? 0;
      if (status >= 400 &&
          status < 500 &&
          data is Map &&
          data['detail'] is String) {
        throw ValidationFailure(data['detail'] as String);
      }
      throw const NetworkFailure('Unable to update your library. Try again.');
    }
  }
}
