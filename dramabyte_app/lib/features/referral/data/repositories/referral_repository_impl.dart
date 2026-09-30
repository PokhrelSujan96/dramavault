import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/features/referral/data/datasources/referral_remote_source.dart';
import 'package:dramabyte_app/features/referral/data/models/referral_summary_model.dart';
import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';
import 'package:dramabyte_app/features/referral/domain/repositories/referral_repository.dart';

final class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._remote, this._cache, this._realtime);

  final ReferralRemoteSource _remote;
  final JsonCache _cache;
  final RealtimeService _realtime;

  String _key(String userId) => 'cache_referral_$userId';

  @override
  Future<ReferralSummary?> cached(String userId) async {
    final json = await _cache.read(_key(userId));
    return json == null ? null : ReferralSummaryModel(json).toEntity();
  }

  @override
  Future<ReferralSummary> fetch(String userId) async {
    try {
      final model = await _remote.summary();
      await _cache.write(_key(userId), model.json);
      return model.toEntity();
    } on DioException catch (error) {
      AppLogger.error(
        'Referral request failed: ${error.type.name} '
        'status=${error.response?.statusCode} body=${error.response?.data}',
        error: error,
      );
      throw const NetworkFailure('Unable to load referral details. Try again.');
    }
  }

  @override
  Stream<void> changes(String userId) =>
      _realtime.changes('referral_rewards', column: 'user_id', userId: userId);
}
