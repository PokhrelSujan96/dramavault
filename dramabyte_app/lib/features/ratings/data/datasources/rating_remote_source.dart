import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/ratings/data/models/rating_summary_model.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';

final class RatingRemoteSource {
  RatingRemoteSource(this._client);

  final ApiClient _client;

  String _path(RatingTarget target, String id) =>
      '/ratings/${target == RatingTarget.series ? 'series' : 'episodes'}/$id';

  Future<RatingSummaryModel> rate(
    RatingTarget target,
    String id,
    int rating,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      _path(target, id),
      data: {'rating': rating},
    );
    return RatingSummaryModel(response.data ?? const {});
  }

  Future<RatingSummaryModel> clear(RatingTarget target, String id) async {
    final response = await _client.dio.delete<Map<String, dynamic>>(
      _path(target, id),
    );
    return RatingSummaryModel(response.data ?? const {});
  }
}
