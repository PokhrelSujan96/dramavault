import 'dart:io';

import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_database.dart';
import 'package:dramabyte_app/features/discover/data/datasources/reel_file_store.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/cache_repository.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class CacheRepositoryImpl implements CacheRepository {
  CacheRepositoryImpl(this._files, this._reels, this._json);

  final ReelFileStore _files;
  final ReelDatabase _reels;
  final JsonCache _json;

  @override
  Future<int> size() async {
    final images = Directory(
      p.join((await getTemporaryDirectory()).path, 'libCachedImageData'),
    );
    return await _files.totalBytes() + await _directoryBytes(images);
  }

  @override
  Future<void> clear() async {
    await _files.deleteAll();
    await _reels.clearFiles();
    await DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    await _json.clear();
  }

  Future<int> _directoryBytes(Directory directory) async {
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }
}
