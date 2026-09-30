part of 'search_cubit.dart';

enum SearchStatus { idle, loading, loaded, failure }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.idle,
    this.query = '',
    this.results = const [],
    this.recents = const [],
    this.error,
  });

  final SearchStatus status;
  final String query;
  final List<SearchResult> results;
  final List<String> recents;
  final String? error;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<SearchResult>? results,
    List<String>? recents,
    String? error,
  }) => SearchState(
    status: status ?? this.status,
    query: query ?? this.query,
    results: results ?? this.results,
    recents: recents ?? this.recents,
    error: error,
  );

  @override
  List<Object?> get props => [status, query, results, recents, error];
}
