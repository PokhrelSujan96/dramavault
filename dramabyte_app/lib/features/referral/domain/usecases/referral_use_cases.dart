import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';
import 'package:dramabyte_app/features/referral/domain/repositories/referral_repository.dart';

final class GetCachedReferral implements UseCase<ReferralSummary?, String> {
  GetCachedReferral(this._repository);

  final ReferralRepository _repository;

  @override
  Future<ReferralSummary?> call(String params) => _repository.cached(params);
}

final class GetReferralSummary implements UseCase<ReferralSummary, String> {
  GetReferralSummary(this._repository);

  final ReferralRepository _repository;

  @override
  Future<ReferralSummary> call(String params) => _repository.fetch(params);
}

final class WatchReferralChanges {
  WatchReferralChanges(this._repository);

  final ReferralRepository _repository;

  Stream<void> call(String userId) => _repository.changes(userId);
}
