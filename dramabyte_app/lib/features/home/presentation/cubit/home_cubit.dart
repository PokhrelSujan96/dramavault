import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/usecases/home_use_cases.dart';

class HomeCubit extends SyncedCubit<HomeFeed> {
  HomeCubit(super.auth, GetCachedHome cached, GetHome fetch)
    : super(
        readCache: (_) => cached(const NoParams()),
        fetch: (_) => fetch(const NoParams()),
        changes: (_) => const Stream.empty(),
      );
}
