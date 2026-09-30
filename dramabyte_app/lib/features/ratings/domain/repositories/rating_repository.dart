import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';

abstract interface class RatingRepository {
  Future<RatingSummary> rate(RatingTarget target, String id, int rating);
  Future<RatingSummary> clear(RatingTarget target, String id);
}
