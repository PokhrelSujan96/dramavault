import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';
import 'package:dramabyte_app/features/discover/domain/usecases/discover_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'discover_state.dart';

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit(this._cached, this._page, this._offline)
    : super(const DiscoverState());

  final GetCachedReelPage _cached;
  final GetReelPage _page;
  final GetOfflineReels _offline;
  bool _paged = false;

  Future<void> load() async {
    _paged = false;
    final cached = await _cached(const NoParams());
    emit(
      cached == null
          ? const DiscoverState()
          : DiscoverState(
              status: DiscoverStatus.ready,
              reels: cached.items,
              nextCursor: cached.nextCursor,
            ),
    );
    try {
      final page = await _page(null);
      emit(
        cached == null
            ? DiscoverState(
                status: DiscoverStatus.ready,
                reels: page.items,
                nextCursor: page.nextCursor,
              )
            : _merged(page),
      );
    } on Failure catch (failure) {
      if (cached != null) {
        return emit(
          state.copyWith(offline: true, nextCursor: state.nextCursor),
        );
      }
      final saved = await _offline(const NoParams());
      emit(
        saved.isEmpty
            ? DiscoverState(
                status: DiscoverStatus.failure,
                error: failure.message,
              )
            : DiscoverState(
                status: DiscoverStatus.ready,
                reels: saved,
                offline: true,
              ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.status != DiscoverStatus.ready) return load();
    try {
      emit(_merged(await _page(null)));
    } on Failure {
      return;
    }
  }

  DiscoverState _merged(ReelPage page) {
    final fresh = {for (final reel in page.items) reel.episodeId: reel};
    final shown = {for (final reel in state.reels) reel.episodeId};
    return state.copyWith(
      status: DiscoverStatus.ready,
      reels: [
        for (final reel in state.reels) fresh[reel.episodeId] ?? reel,
        for (final reel in page.items)
          if (!shown.contains(reel.episodeId)) reel,
      ],
      nextCursor: _paged ? state.nextCursor : page.nextCursor,
      loadingMore: false,
      offline: false,
    );
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.offline) return;
    emit(state.copyWith(loadingMore: true, nextCursor: state.nextCursor));
    try {
      final page = await _page(state.nextCursor);
      _paged = true;
      final known = {for (final reel in state.reels) reel.episodeId};
      emit(
        state.copyWith(
          reels: [
            ...state.reels,
            for (final reel in page.items)
              if (!known.contains(reel.episodeId)) reel,
          ],
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } on Failure {
      emit(state.copyWith(loadingMore: false, nextCursor: state.nextCursor));
    }
  }
}
