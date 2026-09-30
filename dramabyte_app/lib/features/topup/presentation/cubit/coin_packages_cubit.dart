import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/usecases/topup_use_cases.dart';

class CoinPackagesCubit extends SyncedCubit<List<CoinPackage>> {
  CoinPackagesCubit(
    super.auth,
    GetCachedCoinPackages cached,
    GetCoinPackages fetch,
    WatchCoinPackageChanges changes,
  ) : super(
        readCache: (_) => cached(const NoParams()),
        fetch: (_) => fetch(const NoParams()),
        changes: (_) => changes(),
      );
}
