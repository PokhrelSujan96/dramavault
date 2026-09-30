import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/engagement/data/datasources/engagement_remote_source.dart';
import 'package:dramabyte_app/features/engagement/data/datasources/view_batcher.dart';
import 'package:dramabyte_app/features/engagement/domain/repositories/engagement_repository.dart';

final class EngagementRepositoryImpl implements EngagementRepository {
  EngagementRepositoryImpl(this._remote, this._batcher);

  final EngagementRemoteSource _remote;
  final ViewBatcher _batcher;

  @override
  Future<void> setLike(String episodeId, {required bool liked}) async {
    try {
      await _remote.setLike(episodeId, liked: liked);
    } on DioException catch (error) {
      AppLogger.error(
        'Like request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      final data = error.response?.data;
      final status = error.response?.statusCode ?? 0;
      if (status >= 400 &&
          status < 500 &&
          data is Map &&
          data['detail'] is String) {
        throw ValidationFailure(data['detail'] as String);
      }
      throw const NetworkFailure('Could not update your like. Try again.');
    }
  }

  @override
  void recordView(String episodeId) => _batcher.record(episodeId);

  @override
  Future<void> flushViews() => _batcher.flush();
}
