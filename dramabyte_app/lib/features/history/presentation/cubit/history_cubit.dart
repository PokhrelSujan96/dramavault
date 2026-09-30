import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/usecases/history_use_cases.dart';

class HistoryCubit extends SyncedCubit<List<HistoryItem>> {
  HistoryCubit(
    super.auth,
    GetCachedHistory cached,
    GetRecentHistory fetch,
    WatchHistoryChanges changes,
  ) : super(readCache: cached.call, fetch: fetch.call, changes: changes.call);
}
