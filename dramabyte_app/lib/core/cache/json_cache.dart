import 'dart:convert';

import 'package:dramabyte_app/core/security/secure_storage.dart';

final class JsonCache {
  JsonCache(this._storage);

  static const _prefix = 'cache_';

  final SecureStorage _storage;

  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await _storage.read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> clear() async {
    for (final key in await _storage.keys()) {
      if (key.startsWith(_prefix)) await _storage.delete(key);
    }
  }

  Future<void> write(String key, Map<String, dynamic> value) =>
      _storage.write(key, jsonEncode(value));
}
