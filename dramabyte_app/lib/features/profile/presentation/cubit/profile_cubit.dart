import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/features/profile/domain/usecases/profile_use_cases.dart';

class ProfileCubit extends SyncedCubit<UserProfile> {
  ProfileCubit(
    super.auth,
    GetCachedProfile cached,
    GetMyProfile fetch,
    WatchProfileChanges changes,
  ) : super(readCache: cached.call, fetch: fetch.call, changes: changes.call);
}
