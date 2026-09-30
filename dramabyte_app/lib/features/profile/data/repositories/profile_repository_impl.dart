import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/features/profile/data/datasources/profile_remote_source.dart';
import 'package:dramabyte_app/features/profile/data/models/user_profile_model.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/features/profile/domain/repositories/profile_repository.dart';

final class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._remote, this._cache, this._realtime);

  final ProfileRemoteSource _remote;
  final JsonCache _cache;
  final RealtimeService _realtime;

  String _key(String userId) => 'cache_profile_$userId';

  @override
  Future<UserProfile?> cached(String userId) async {
    final json = await _cache.read(_key(userId));
    return json == null ? null : UserProfileModel(json).toEntity();
  }

  @override
  Future<UserProfile> fetch(String userId) async {
    try {
      final model = await _remote.me();
      await _cache.write(_key(userId), model.json);
      return model.toEntity();
    } on DioException catch (error) {
      AppLogger.error(
        'Profile request failed: ${error.type.name} '
        'status=${error.response?.statusCode} body=${error.response?.data}',
        error: error,
      );
      throw const NetworkFailure('Unable to load your profile. Try again.');
    }
  }

  @override
  Stream<void> changes(String userId) =>
      _realtime.changes('profiles', column: 'id', userId: userId);
}
