import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_button.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rated_builder.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_colors.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelRatingButton extends StatelessWidget {
  const ReelRatingButton({super.key, required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    return RatedBuilder(
      target: RatingTarget.episode,
      id: reel.episodeId,
      fallback: reel.rating,
      builder: (context, summary) {
        final mine = summary.myRating;
        return ReelActionButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              mine == null ? Icons.star_outline_rounded : Icons.star_rounded,
              key: ValueKey(mine != null),
              size: 30.sp,
              color: mine == null ? Colors.white : RatingColors.gold,
            ),
          ),
          label: mine != null
              ? '$mine/10'
              : (summary.hasRatings ? summary.averageLabel : 'Rate'),
          onTap: () => showRatingSheet(
            context,
            target: RatingTarget.episode,
            id: reel.episodeId,
            title: reel.title,
            subtitle: '${reel.title} · ${reel.episodeLabel}',
          ),
        );
      },
    );
  }
}
