import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelWatchChip extends StatelessWidget {
  const ReelWatchChip({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(100.r),
        border: Border.all(color: FlareColors.primary.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlareSvgIcon('play', size: 16.sp, color: FlareColors.primary),
          SizedBox(width: 6.w),
          FlareText('Watch $count episodes').sm.white,
        ],
      ),
    );
  }
}
