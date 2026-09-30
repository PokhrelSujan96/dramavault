import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/discover/data/datasources/discover_remote_source.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_database.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_file_store.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/discover_repository.dart';

final class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(
    this._remote,
    this._database,
    this._files,
    this._cache,
  );

  static const _firstPageKey = 'cache_discover_first_page';
  final DiscoverRemoteSource _remote;
  final ReelDatabase _database;
  final ReelFileStore _files;
  final JsonCache _cache;

  @override
  Future<ReelPage> fetchPage({String? cursor}) async {
    try {
      final page = await _remote.page(cursor);
      await _refreshChangedFiles(page.items);
      await _database.upsert([for (final item in page.items) item.json]);
      if (cursor == null) {
        await _cache.write(_firstPageKey, {
          'items': [for (final item in page.items) item.json],
          'next_cursor': page.nextCursor,
        });
      }
      return page.toEntity();
    } on DioException catch (error) {
      AppLogger.error(
        'Discover request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      throw const NetworkFailure('Unable to load episodes. Try again.');
    }
  }

  Future<void> _refreshChangedFiles(List<ReelModel> items) async {
    for (final item in items) {
      final reel = item.toEntity();
      if (reel == null) continue;
      final cached = await _database.filePath(reel.episodeId);
      if (cached == null) continue;
      final cachedRevision = await _database.revision(reel.episodeId) ?? '';
      final changed = cachedRevision != reel.videoRevision;
      if (!changed) continue;
      if (await _files.exists(cached)) await _files.delete(cached);
      await _database.clearFile(reel.episodeId);
    }
  }

  @override
  Future<ReelPage?> cachedFirstPage() async {
    final json = await _cache.read(_firstPageKey);
    if (json == null) return null;
    final page = ReelPageModel.fromJson(json).toEntity();
    return page.items.isEmpty ? null : page;
  }

  @override
  Future<List<Reel>> offlineReels() async {
    final reels = <Reel>[];
    for (final row in await _database.downloaded()) {
      final id = row['episode_id'] as String;
      final path = row['file_path'] as String;
      if (!await _files.exists(path)) {
        await _database.clearFile(id);
        continue;
      }
      final reel = ReelModel(row).toEntity();
      if (reel != null) reels.add(reel);
    }
    return reels;
  }
}
