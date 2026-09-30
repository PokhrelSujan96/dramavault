import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/ratings/data/datasources/rating_remote_source.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/domain/repositories/rating_repository.dart';

final class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl(this._remote);

  final RatingRemoteSource _remote;

  @override
  Future<RatingSummary> rate(RatingTarget target, String id, int rating) =>
      _guard(() async => (await _remote.rate(target, id, rating)).toEntity());

  @override
  Future<RatingSummary> clear(RatingTarget target, String id) =>
      _guard(() async => (await _remote.clear(target, id)).toEntity());

  Future<RatingSummary> _guard(Future<RatingSummary> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'Rating request failed: ${error.type.name} '
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
      throw const NetworkFailure('Could not save your rating. Try again.');
    }
  }
}
