import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final class ReelFileStore {
  final Dio _dio = Dio(BaseOptions(receiveTimeout: const Duration(minutes: 2)));
  final _active = <String, CancelToken>{};

  Future<({String path, int bytes})> download(String id, String url) async {
    final directory = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'reels'),
    );
    await directory.create(recursive: true);
    final target = p.join(directory.path, '$id.mp4');
    final partial = '$target.part';
    final token = _active[id] = CancelToken();
    try {
      await _dio.download(url, partial, cancelToken: token);
      await File(partial).rename(target);
      return (path: target, bytes: await File(target).length());
    } on Object {
      await _delete(partial);
      rethrow;
    } finally {
      _active.remove(id);
    }
  }

  void keepOnly(Set<String> ids) {
    for (final entry in _active.entries) {
      if (!ids.contains(entry.key)) entry.value.cancel('out of range');
    }
  }

  Future<Directory> get _directory async =>
      Directory(p.join((await getApplicationSupportDirectory()).path, 'reels'));

  Future<int> totalBytes() async {
    final directory = await _directory;
    if (!await directory.exists()) return 0;
    var total = 0;
    await for (final entity in directory.list()) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  Future<void> deleteAll() async {
    for (final token in _active.values) {
      token.cancel('cache cleared');
    }
    final directory = await _directory;
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<bool> exists(String path) => File(path).exists();

  Future<void> delete(String path) => _delete(path);

  Future<void> _delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
