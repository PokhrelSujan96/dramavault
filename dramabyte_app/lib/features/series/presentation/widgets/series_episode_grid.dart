import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_episode_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesEpisodeGrid extends StatelessWidget {
  const SeriesEpisodeGrid({
    super.key,
    required this.episodes,
    required this.currentEpisodeId,
    required this.onTap,
  });

  final List<EpisodeSummary> episodes;
  final String? currentEpisodeId;
  final ValueChanged<EpisodeSummary> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
      itemCount: episodes.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 10.h,
        crossAxisSpacing: 10.w,
      ),
      itemBuilder: (_, index) => SeriesEpisodeTile(
        episode: episodes[index],
        isCurrent: episodes[index].episodeId == currentEpisodeId,
        onTap: () => onTap(episodes[index]),
      ),
    );
  }
}
