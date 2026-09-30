import 'dart:async';

import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/domain/usecases/library_use_cases.dart';

class LibraryCubit extends SyncedCubit<List<LibraryItem>> {
  LibraryCubit(
    super.auth,
    GetCachedLibrary cached,
    GetLibrary fetch,
    WatchLibraryChanges changes,
    this._add,
    this._remove,
  ) : super(readCache: cached.call, fetch: fetch.call, changes: changes.call);

  final AddToLibrary _add;
  final RemoveFromLibrary _remove;

  List<LibraryItem>? get items {
    final current = state;
    return current is ResourceLoaded<List<LibraryItem>> ? current.value : null;
  }

  bool isSaved(String seriesId) =>
      items?.any((item) => item.seriesId == seriesId) ?? false;

  List<LibraryItem> _reinsert(
    List<LibraryItem> list,
    int at,
    LibraryItem item,
  ) {
    final restored = List<LibraryItem>.of(list);
    restored.insert(at.clamp(0, restored.length), item);
    return restored;
  }

  Future<String?> toggle(LibraryItem item) async {
    final before = items;
    if (before == null) return 'Your library is still loading. Try again.';
    final index = before.indexWhere((e) => e.seriesId == item.seriesId);
    final wasSaved = index >= 0;
    update(
      (list) => wasSaved
          ? [
              for (final e in list)
                if (e.seriesId != item.seriesId) e,
            ]
          : [item, ...list],
    );
    try {
      await (wasSaved ? _remove(item.seriesId) : _add(item.seriesId));
    } on Failure catch (failure) {
      update(
        (list) => wasSaved
            ? _reinsert(list, index, before[index])
            : [
                for (final e in list)
                  if (e.seriesId != item.seriesId) e,
              ],
      );
      return failure.message;
    }
    unawaited(refresh());
    return null;
  }
}
