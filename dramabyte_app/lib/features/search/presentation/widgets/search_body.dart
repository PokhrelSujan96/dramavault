import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:dramabyte_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_message_view.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_recent_list.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_result_tile.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_skeleton.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_trending_list.dart';
import 'package:flutter/material.dart';

class SearchBody extends StatelessWidget {
  const SearchBody({
    super.key,
    required this.state,
    required this.cubit,
    required this.suggestions,
    required this.onPickRecent,
    required this.onOpenSeries,
  });

  final SearchState state;
  final SearchCubit cubit;
  final List<SearchSuggestion> suggestions;
  final ValueChanged<String> onPickRecent;
  final ValueChanged<String> onOpenSeries;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(key: ValueKey(_slot), child: _content()),
    );
  }

  String get _slot => switch (state.status) {
    SearchStatus.idle => 'idle',
    SearchStatus.loading when state.results.isEmpty => 'loading',
    SearchStatus.failure => 'failure',
    _ => state.results.isEmpty ? 'empty' : 'results',
  };

  Widget _content() => switch (state.status) {
    SearchStatus.idle => ListView(
      children: [
        if (state.recents.isNotEmpty)
          SearchRecentList(
            recents: state.recents,
            onPick: onPickRecent,
            onRemove: cubit.removeRecent,
            onClear: cubit.clearRecents,
          ),
        if (suggestions.isNotEmpty)
          SearchTrendingList(
            suggestions: suggestions,
            onOpen: (item) => onOpenSeries(item.seriesId),
          ),
      ],
    ),
    SearchStatus.loading when state.results.isEmpty => const SearchSkeleton(),
    SearchStatus.failure => SearchMessageView(
      title: 'Something went wrong',
      message: state.error,
      actionLabel: 'Try again',
      onAction: cubit.retry,
    ),
    _ when state.results.isEmpty => SearchMessageView(
      title: 'No results for "${state.query}"',
      message: 'Try a different title or genre.',
    ),
    _ => _Results(
      results: state.results,
      query: state.query,
      loading: state.status == SearchStatus.loading,
      onTap: (result) {
        cubit.select(result);
        onOpenSeries(result.seriesId);
      },
    ),
  };
}

class _Results extends StatelessWidget {
  const _Results({
    required this.results,
    required this.query,
    required this.loading,
    required this.onTap,
  });

  final List<SearchResult> results;
  final String query;
  final bool loading;
  final ValueChanged<SearchResult> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 2,
          child: loading ? const LinearProgressIndicator() : null,
        ),
        Expanded(
          child: ListView.builder(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: results.length,
            itemBuilder: (_, index) => SearchResultTile(
              result: results[index],
              query: query,
              onTap: () => onTap(results[index]),
            ),
          ),
        ),
      ],
    );
  }
}
