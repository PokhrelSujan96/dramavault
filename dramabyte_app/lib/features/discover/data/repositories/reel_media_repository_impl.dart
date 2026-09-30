import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_database.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_file_store.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_source.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/reel_media_repository.dart';

final class ReelMediaRepositoryImpl implements ReelMediaRepository {
  ReelMediaRepositoryImpl(this._database, this._files);

  static const _maxBytes = 300 * 1024 * 1024;
  final ReelDatabase _database;
  final ReelFileStore _files;
  final _inFlight = <String, Future<void>>{};

  @override
  Future<ReelSource> resolve(Reel reel) async {
    final path = await _database.filePath(reel.episodeId);
    if (path != null && await _files.exists(path)) {
      return ReelSource(path, isLocal: true);
    }
    return ReelSource(reel.videoUrl, isLocal: false);
  }

  @override
  Future<void> cache(Reel reel) {
    if (reel.videoUrl.isEmpty) return Future.value();
    return _inFlight[reel.episodeId] ??= _download(
      reel,
    ).whenComplete(() => _inFlight.remove(reel.episodeId));
  }

  @override
  void keepDownloads(Set<String> episodeIds) => _files.keepOnly(episodeIds);

  @override
  Future<void> markPlayed(String episodeId) => _database.touch(episodeId);

  Future<void> _download(Reel reel) async {
    try {
      final path = await _database.filePath(reel.episodeId);
      if (path != null && await _files.exists(path)) {
        await _files.delete(path);
        await _database.clearFile(reel.episodeId);
      }
      final file = await _files.download(reel.episodeId, reel.videoUrl);
      await _database.setFile(reel.episodeId, file.path, file.bytes);
      await _evict(keep: reel.episodeId);
    } on Object catch (error) {
      if (error is DioException && CancelToken.isCancel(error)) return;
      AppLogger.warning('Reel download failed', error: error);
    }
  }

  Future<void> _evict({required String keep}) async {
    final rows = (await _database.downloaded()).reversed.toList();
    var total = rows.fold<int>(0, (sum, row) => sum + (row['bytes'] as int));
    for (final row in rows) {
      final id = row['episode_id'] as String;
      if (total <= _maxBytes) break;
      if (id == keep) continue;
      await _files.delete(row['file_path'] as String);
      await _database.clearFile(id);
      total -= row['bytes'] as int;
    }
  }
}
