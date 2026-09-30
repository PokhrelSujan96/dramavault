import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';

final class RatingSummaryModel {
  const RatingSummaryModel(this.json);

  final Map<String, dynamic> json;

  RatingSummary toEntity() {
    final average = json['average'];
    final count = json['count'];
    final mine = json['my_rating'];
    return RatingSummary(
      average: average is num ? average.toDouble() : null,
      count: count is num ? count.toInt() : 0,
      myRating: mine is num ? mine.toInt() : null,
    );
  }
}
