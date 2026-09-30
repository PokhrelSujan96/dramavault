import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rated_builder.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_badge.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_colors.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_sheet.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesRatingRow extends StatelessWidget {
  const SeriesRatingRow({super.key, required this.series});

  final SeriesDetails series;

  @override
  Widget build(BuildContext context) {
    return RatedBuilder(
      target: RatingTarget.series,
      id: series.seriesId,
      fallback: series.rating,
      builder: (context, summary) {
        final mine = summary.myRating;
        return Wrap(
          spacing: 12.w,
          runSpacing: 6.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RatingBadge(summary: summary),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showRatingSheet(
                context,
                target: RatingTarget.series,
                id: series.seriesId,
                title: series.title,
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(
                    color: mine == null ? Colors.grey : RatingColors.gold,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mine == null
                          ? Icons.star_outline_rounded
                          : Icons.star_rounded,
                      size: 15.sp,
                      color: mine == null ? Colors.grey : RatingColors.gold,
                    ),
                    SizedBox(width: 4.w),
                    FlareText(
                      mine == null ? 'Rate' : 'Your rating: $mine',
                    ).xs.semiBold,
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
