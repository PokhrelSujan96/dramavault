import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/domain/usecases/search_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._search,
    this._recents,
    this._save,
    this._remove,
    this._clear, {
    this.debounce = const Duration(milliseconds: 350),
  }) : super(const SearchState());

  static const minLength = 2;
  final SearchSeries _search;
  final GetRecentSearches _recents;
  final SaveRecentSearch _save;
  final RemoveRecentSearch _remove;
  final ClearRecentSearches _clear;
  final Duration debounce;
  final _memo = <String, List<SearchResult>>{};
  Timer? _timer;
  int _request = 0;

  Future<void> init() async =>
      emit(state.copyWith(recents: await _recents(const NoParams())));

  void onQueryChanged(String raw) {
    final query = raw.trim();
    _timer?.cancel();
    _request++;
    if (query.length < minLength) {
      return emit(SearchState(recents: state.recents));
    }
    final memo = _memo[query.toLowerCase()];
    if (memo != null) {
      return emit(
        state.copyWith(
          status: SearchStatus.loaded,
          query: query,
          results: memo,
        ),
      );
    }
    emit(state.copyWith(status: SearchStatus.loading, query: query));
    _timer = Timer(debounce, () => _run(query));
  }

  Future<void> submit(String raw) async {
    final query = raw.trim();
    if (query.length < minLength) return;
    _timer?.cancel();
    emit(state.copyWith(status: SearchStatus.loading, query: query));
    await Future.wait([_run(query), _remember(query)]);
  }

  Future<void> retry() => _run(state.query);

  Future<void> select(SearchResult result) =>
      _remember(state.query.length >= minLength ? state.query : result.title);

  Future<void> removeRecent(String query) async {
    await _remove(query);
    emit(state.copyWith(recents: await _recents(const NoParams())));
  }

  Future<void> clearRecents() async {
    await _clear(const NoParams());
    emit(state.copyWith(recents: const []));
  }

  Future<void> _run(String query) async {
    final id = ++_request;
    try {
      final results = await _search(query);
      _memo[query.toLowerCase()] = results;
      if (isClosed || id != _request) return;
      emit(
        state.copyWith(
          status: SearchStatus.loaded,
          query: query,
          results: results,
        ),
      );
    } on Failure catch (failure) {
      if (isClosed || id != _request) return;
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          query: query,
          error: failure.message,
        ),
      );
    }
  }

  Future<void> _remember(String query) async {
    await _save(query);
    if (!isClosed) {
      emit(state.copyWith(recents: await _recents(const NoParams())));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
