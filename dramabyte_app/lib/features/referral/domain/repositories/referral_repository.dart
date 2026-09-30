import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';

abstract interface class ReferralRepository {
  Future<ReferralSummary?> cached(String userId);
  Future<ReferralSummary> fetch(String userId);
  Stream<void> changes(String userId);
}
