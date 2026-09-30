import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/domain/repositories/rating_repository.dart';

final class RateParams {
  const RateParams(this.target, this.id, this.rating);

  final RatingTarget target;
  final String id;
  final int rating;
}

final class RateTitle implements UseCase<RatingSummary, RateParams> {
  RateTitle(this._repository);

  final RatingRepository _repository;

  @override
  Future<RatingSummary> call(RateParams params) =>
      _repository.rate(params.target, params.id, params.rating);
}

final class ClearParams {
  const ClearParams(this.target, this.id);

  final RatingTarget target;
  final String id;
}

final class ClearRating implements UseCase<RatingSummary, ClearParams> {
  ClearRating(this._repository);

  final RatingRepository _repository;

  @override
  Future<RatingSummary> call(ClearParams params) =>
      _repository.clear(params.target, params.id);
}
