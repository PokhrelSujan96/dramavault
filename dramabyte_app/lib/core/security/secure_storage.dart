import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<Set<String>> keys();
  Future<void> clear();
}

final class FlutterSecureStorageService implements SecureStorage {
  FlutterSecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Set<String>> keys() async => (await _storage.readAll()).keys.toSet();

  @override
  Future<void> clear() => _storage.deleteAll();
}
