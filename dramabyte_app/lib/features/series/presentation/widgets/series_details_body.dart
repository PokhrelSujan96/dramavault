import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_cubit.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_bookmark_button.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_backdrop.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_episode_grid.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_range_tabs.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_sheet.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SeriesDetailsBody extends StatefulWidget {
  const SeriesDetailsBody({super.key, required this.series});

  final SeriesDetails series;

  @override
  State<SeriesDetailsBody> createState() => _SeriesDetailsBodyState();
}

class _SeriesDetailsBodyState extends State<SeriesDetailsBody> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    _seedRating();
  }

  @override
  void didUpdateWidget(SeriesDetailsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.rating != widget.series.rating) _seedRating();
  }

  void _seedRating() => context.read<RatingsCubit>().seed(
    RatingTarget.series,
    widget.series.seriesId,
    widget.series.rating,
  );

  String? _currentEpisodeId(ResourceState<List<HistoryItem>> history) {
    if (history is! ResourceLoaded<List<HistoryItem>>) return null;
    for (final item in history.value) {
      if (item.seriesId == widget.series.seriesId) return item.episodeId;
    }
    return null;
  }

  void _open(EpisodeSummary episode) {
    if (episode.locked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This episode is locked. Unlocking is coming soon.'),
        ),
      );
      return;
    }
    context.pushNamed(
      AppRoutes.watchName,
      pathParameters: {'seriesId': widget.series.seriesId},
      queryParameters: {'episode': '${episode.episodeNumber}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final ranges = widget.series.ranges;
    final currentId = _currentEpisodeId(context.watch<HistoryCubit>().state);
    final currentRange = currentId == null
        ? -1
        : ranges.indexWhere((range) => range.contains(currentId));
    final tab = (_selected ?? (currentRange < 0 ? 0 : currentRange)).clamp(
      0,
      ranges.length - 1,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        SeriesBackdrop(imageUrl: widget.series.thumbnailUrl),
        SeriesSheet(
          children: [
            SeriesSummary(series: widget.series),
            SizedBox(height: 20.h),
            SeriesRangeTabs(
              ranges: ranges,
              selected: tab,
              onSelect: (index) => setState(() => _selected = index),
            ),
            SeriesEpisodeGrid(
              episodes: ranges[tab].episodes,
              currentEpisodeId: currentId,
              onTap: _open,
            ),
          ],
        ),
        Align(
          alignment: Alignment.topLeft,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(12.r),
              child: LibraryBookmarkButton(
                item: LibraryItem(
                  seriesId: widget.series.seriesId,
                  title: widget.series.title,
                  genre: widget.series.genre,
                  thumbnailUrl: widget.series.thumbnailUrl,
                  episodeCount: widget.series.episodeCount,
                  freeEpisodeCount: widget.series.freeEpisodeCount,
                  savedAt: DateTime.now(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
