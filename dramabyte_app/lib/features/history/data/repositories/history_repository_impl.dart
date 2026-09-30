import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/features/history/data/datasources/history_remote_source.dart';
import 'package:dramabyte_app/features/history/data/models/history_models.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_page.dart';
import 'package:dramabyte_app/features/history/domain/repositories/history_repository.dart';

final class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._remote, this._cache, this._realtime);

  static const _stripSize = 10;
  static const _pageSize = 20;
  final HistoryRemoteSource _remote;
  final JsonCache _cache;
  final RealtimeService _realtime;
  final _pending = <String, int>{};

  String _key(String userId) => 'cache_history_$userId';

  @override
  Future<List<HistoryItem>?> cached(String userId) async {
    final items = (await _cache.read(_key(userId)))?['items'];
    if (items is! List) return null;
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) ?HistoryModel(item).toEntity(),
    ];
  }

  @override
  Future<List<HistoryItem>> recent(String userId) => _guard(() async {
    final page = await _remote.page(null, _stripSize);
    await _cache.write(_key(userId), {
      'items': [for (final item in page.items) item.json],
    });
    return page.toEntity().items;
  });

  @override
  Stream<void> changes(String userId) =>
      _realtime.changes('watch_history', column: 'user_id', userId: userId);

  @override
  Future<HistoryPage> page(String? cursor) =>
      _guard(() async => (await _remote.page(cursor, _pageSize)).toEntity());

  @override
  Future<void> record(String episodeId, int seconds) async {
    _pending[episodeId] = seconds;
    for (final entry in {..._pending}.entries) {
      try {
        await _remote.record(entry.key, entry.value);
        _pending.remove(entry.key);
      } on DioException catch (error) {
        final status = error.response?.statusCode ?? 0;
        if (status >= 400 && status < 500) _pending.remove(entry.key);
        AppLogger.warning('Watch record failed', error: error);
        return;
      }
    }
  }

  @override
  Future<void> remove(String? episodeId) =>
      _guard(() => _remote.remove(episodeId));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'History request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      throw const NetworkFailure('Unable to load your history. Try again.');
    }
  }
}
