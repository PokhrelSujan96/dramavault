import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/usecases/history_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'history_list_state.dart';

class HistoryListCubit extends Cubit<HistoryListState> {
  HistoryListCubit(this._page, this._remove) : super(const HistoryListState());

  final GetHistoryPage _page;
  final RemoveHistory _remove;

  Future<void> load() async {
    emit(const HistoryListState());
    try {
      final page = await _page(null);
      emit(
        HistoryListState(
          status: HistoryListStatus.ready,
          items: page.items,
          nextCursor: page.nextCursor,
        ),
      );
    } on Failure catch (failure) {
      emit(
        HistoryListState(
          status: HistoryListStatus.failure,
          error: failure.message,
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.nextCursor == null || state.loadingMore) return;
    emit(state.copyWith(loadingMore: true, nextCursor: state.nextCursor));
    try {
      final page = await _page(state.nextCursor);
      final known = {for (final item in state.items) item.episodeId};
      emit(
        state.copyWith(
          items: [
            ...state.items,
            for (final item in page.items)
              if (!known.contains(item.episodeId)) item,
          ],
          nextCursor: page.nextCursor,
          loadingMore: false,
        ),
      );
    } on Failure {
      emit(state.copyWith(loadingMore: false, nextCursor: state.nextCursor));
    }
  }

  Future<void> remove(String? episodeId) async {
    final before = state;
    emit(
      state.copyWith(
        items: [
          if (episodeId != null)
            for (final item in state.items)
              if (item.episodeId != episodeId) item,
        ],
        nextCursor: episodeId == null ? null : state.nextCursor,
      ),
    );
    try {
      await _remove(episodeId);
    } on Failure catch (failure) {
      emit(
        before.copyWith(notice: failure.message, nextCursor: before.nextCursor),
      );
    }
  }
}
