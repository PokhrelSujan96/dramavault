import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/network/token_refresher.dart';
import 'package:dramabyte_app/core/security/secure_storage.dart';
import 'package:dramabyte_app/core/security/security_keys.dart';
import 'package:dramabyte_app/features/authentication/data/datasources/auth_remote_source.dart';
import 'package:dramabyte_app/features/authentication/data/datasources/google_sign_in_source.dart';
import 'package:dramabyte_app/features/authentication/data/models/auth_result_model.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';

final class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._google,
    this._storage,
    this._refresher,
  );

  final AuthRemoteSource _remote;
  final GoogleSignInSource _google;
  final SecureStorage _storage;
  final TokenRefresher _refresher;

  @override
  Future<AuthUser?> cachedUser() async {
    final refreshToken = await _storage.read(SecurityKeys.refreshToken);
    final userId = await _storage.read(SecurityKeys.userId);
    if (refreshToken == null || userId == null) return null;
    return AuthUser(userId);
  }

  @override
  Future<AuthUser?> restoreSession() async {
    if (await _refresher.refresh() != null) return cachedUser();
    if (await _storage.read(SecurityKeys.refreshToken) == null) return null;
    throw const NetworkFailure('Unable to reach DramaByte.');
  }

  @override
  Future<AuthUser?> signInWithGoogle(String? referralCode) async {
    final idToken = await _google.idToken();
    if (idToken == null) return null;
    try {
      return await _persist(await _remote.google(idToken, referralCode));
    } on DioException catch (error) {
      AppLogger.error(
        'Auth request failed: ${error.type.name} '
        '${error.requestOptions.uri} '
        'status=${error.response?.statusCode} '
        'body=${error.response?.data} cause=${error.error}',
        error: error,
      );
      final detail = error.response?.data;
      throw NetworkFailure(
        detail is Map && detail['detail'] is String
            ? detail['detail'] as String
            : 'Unable to reach DramaByte. Try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _google.signOut();
    await _storage.clear();
  }

  Future<AuthUser> _persist(AuthResultModel result) async {
    await _storage.write(SecurityKeys.accessToken, result.accessToken);
    await _storage.write(SecurityKeys.refreshToken, result.refreshToken);
    await _storage.write(SecurityKeys.userId, result.userId);
    return AuthUser(result.userId);
  }
}
