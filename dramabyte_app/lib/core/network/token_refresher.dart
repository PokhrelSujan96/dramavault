import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/security/secure_storage.dart';
import 'package:dramabyte_app/core/security/security_keys.dart';

final class TokenRefresher {
  TokenRefresher(this._storage);

  final SecureStorage _storage;
  final _refreshed = StreamController<String>.broadcast();
  final _expired = StreamController<void>.broadcast();
  Future<String?>? _inFlight;

  Stream<String> get onRefreshed => _refreshed.stream;

  Stream<void> get onSessionExpired => _expired.stream;

  Future<String?> validAccessToken() async {
    final token = await _storage.read(SecurityKeys.accessToken);
    if (token == null || !_isExpired(token)) return token;
    return refresh();
  }

  Future<String?> refresh() =>
      _inFlight ??= _run().whenComplete(() => _inFlight = null);

  Future<String?> _run() async {
    final refreshToken = await _storage.read(SecurityKeys.refreshToken);
    if (refreshToken == null) return null;
    try {
      final response =
          await Dio(
            BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: AppConfig.connectTimeout,
              receiveTimeout: AppConfig.receiveTimeout,
            ),
          ).post<Map<String, dynamic>>(
            '/auth/refresh',
            data: {'refresh_token': refreshToken},
          );
      final access = response.data!['access_token'] as String;
      await _storage.write(SecurityKeys.accessToken, access);
      await _storage.write(
        SecurityKeys.refreshToken,
        response.data!['refresh_token'] as String,
      );
      _refreshed.add(access);
      return access;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _storage.delete(SecurityKeys.accessToken);
        await _storage.delete(SecurityKeys.refreshToken);
        _expired.add(null);
      }
      return null;
    }
  }

  bool _isExpired(String jwt) {
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(jwt.split('.')[1])),
      );
      final exp = (jsonDecode(payload) as Map<String, dynamic>)['exp'] as int;
      return DateTime.now().millisecondsSinceEpoch ~/ 1000 > exp - 30;
    } on Object {
      return false;
    }
  }
}
