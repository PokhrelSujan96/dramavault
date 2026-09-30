import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';
import 'package:dramabyte_app/features/referral/domain/usecases/referral_use_cases.dart';

class ReferralCubit extends SyncedCubit<ReferralSummary> {
  ReferralCubit(
    super.auth,
    GetCachedReferral cached,
    GetReferralSummary fetch,
    WatchReferralChanges changes,
  ) : super(readCache: cached.call, fetch: fetch.call, changes: changes.call);
}
