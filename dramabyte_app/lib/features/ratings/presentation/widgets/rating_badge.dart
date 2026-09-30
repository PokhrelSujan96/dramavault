import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingBadge extends StatelessWidget {
  const RatingBadge({super.key, required this.summary, this.compact = false});

  final RatingSummary summary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasRatings) {
      return FlareText('No ratings yet').xs.grey;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star_rounded,
          size: (compact ? 14 : 18).sp,
          color: RatingColors.gold,
        ),
        SizedBox(width: 3.w),
        FlareText(summary.averageLabel).size(compact ? 12 : 14).bold,
        if (!compact) FlareText('/10').xs.grey,
        SizedBox(width: 4.w),
        FlareText('(${summary.countLabel})').xs.grey,
      ],
    );
  }
}
