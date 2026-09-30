import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

final class ReelDatabase {
  Database? _db;

  Future<Database> get _database async => _db ??= await openDatabase(
    p.join(await getDatabasesPath(), 'reels.db'),
    version: 2,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE reels(episode_id TEXT PRIMARY KEY, json TEXT NOT NULL, '
      'file_path TEXT, bytes INTEGER NOT NULL DEFAULT 0, '
      'played_at INTEGER NOT NULL DEFAULT 0, video_revision TEXT NOT NULL DEFAULT \'\')',
    ),
    onUpgrade: (db, _, _) => db.execute(
      'ALTER TABLE reels ADD COLUMN video_revision TEXT NOT NULL DEFAULT \'\'',
    ),
  );

  Future<void> upsert(List<Map<String, dynamic>> items) async {
    final batch = (await _database).batch();
    for (final item in items) {
      batch.rawInsert(
        'INSERT INTO reels(episode_id, json, video_revision) VALUES(?, ?, ?) '
        'ON CONFLICT(episode_id) DO UPDATE SET json = excluded.json, '
        'file_path = CASE WHEN reels.video_revision = excluded.video_revision '
        'THEN reels.file_path ELSE NULL END, '
        'bytes = CASE WHEN reels.video_revision = excluded.video_revision '
        'THEN reels.bytes ELSE 0 END, video_revision = excluded.video_revision',
        [item['episode_id'], jsonEncode(item), item['video_revision'] ?? ''],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> downloaded() async {
    final rows = await (await _database).query(
      'reels',
      where: 'file_path IS NOT NULL',
      orderBy: 'played_at DESC',
    );
    return [
      for (final row in rows)
        {...jsonDecode(row['json']! as String) as Map<String, dynamic>, ...row},
    ];
  }

  Future<String?> filePath(String id) async {
    final rows = await (await _database).query(
      'reels',
      columns: ['file_path'],
      where: 'episode_id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.first['file_path'] as String?;
  }

  Future<String?> revision(String id) async {
    final rows = await (await _database).query(
      'reels',
      columns: ['video_revision'],
      where: 'episode_id = ?',
      whereArgs: [id],
    );
    return rows.isEmpty ? null : rows.first['video_revision'] as String?;
  }

  Future<void> setFile(String id, String path, int bytes) async {
    await (await _database).update(
      'reels',
      {'file_path': path, 'bytes': bytes},
      where: 'episode_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearFile(String id) async {
    await (await _database).update(
      'reels',
      {'file_path': null, 'bytes': 0},
      where: 'episode_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearFiles() async {
    await (await _database).update('reels', {'file_path': null, 'bytes': 0});
  }

  Future<void> touch(String id) async {
    await (await _database).update(
      'reels',
      {'played_at': DateTime.now().millisecondsSinceEpoch},
      where: 'episode_id = ?',
      whereArgs: [id],
    );
  }
}
