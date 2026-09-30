import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_watch_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelInfo extends StatelessWidget {
  const ReelInfo({super.key, required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: Offset(0, 1),
            blurRadius: 30.r,
            spreadRadius: 0.r,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FlareText(reel.title).xl2.bold.white,
          SizedBox(height: 6.h),
          if (reel.description.isNotEmpty)
            FlareText(reel.description).sm
                .setColor(Colors.white70)
                .readMore_
                .setReadMoreMaxLines(2)
                .setReadMoreText('See more')
                .setReadMoreColor(Colors.white)
                .size(13.sp),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FlareText(reel.genre).white,
          ),
          if (reel.publishedCount > 1) ...[
            SizedBox(height: 12.h),
            ReelWatchChip(count: reel.publishedCount),
          ],
          SizedBox(height: 12.h),
          Container(
            width: MediaQuery.of(context).size.width.w,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: FlareText('Watch Full Series').center.size(12.sp).white,
          ),
        ],
      ),
    );
  }
}
