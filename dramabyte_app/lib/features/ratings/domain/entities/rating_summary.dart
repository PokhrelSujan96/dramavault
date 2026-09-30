import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:equatable/equatable.dart';

enum RatingTarget { series, episode }

class RatingSummary extends Equatable {
  const RatingSummary({this.average, this.count = 0, this.myRating});

  final double? average;
  final int count;
  final int? myRating;

  String get averageLabel => average == null ? '' : average!.toStringAsFixed(1);

  String get countLabel => compactCount(count);

  bool get hasRatings => average != null && count > 0;

  RatingSummary withMine(int? rating) {
    final had = myRating;
    final total = (average ?? 0) * count;
    var votes = count;
    var sum = total;
    if (had != null) {
      sum -= had;
      votes -= 1;
    }
    if (rating != null) {
      sum += rating;
      votes += 1;
    }
    final next = votes > 0
        ? double.parse((sum / votes).toStringAsFixed(1))
        : null;
    return RatingSummary(
      average: next,
      count: votes < 0 ? 0 : votes,
      myRating: rating,
    );
  }

  @override
  List<Object?> get props => [average, count, myRating];
}
