import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_lock_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SeriesEpisodeTile extends StatelessWidget {
  const SeriesEpisodeTile({
    super.key,
    required this.episode,
    required this.isCurrent,
    required this.onTap,
  });

  final EpisodeSummary episode;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            Center(
              child: isCurrent
                  ? Icon(
                      MdiIcons.equalizer,
                      size: 26.sp,
                      color: FlareColors.primary,
                    )
                  : FlareText('${episode.episodeNumber}').lg.medium,
            ),
            if (episode.locked)
              const Positioned(top: 0, right: 0, child: SeriesLockBadge()),
          ],
        ),
      ),
    );
  }
}
