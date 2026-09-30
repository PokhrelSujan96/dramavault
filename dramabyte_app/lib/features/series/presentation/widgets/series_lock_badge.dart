import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesLockBadge extends StatelessWidget {
  const SeriesLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: FlareColors.primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10.r),
          bottomLeft: Radius.circular(8.r),
        ),
      ),
      child: Icon(Icons.lock, size: 11.sp, color: Colors.white),
    );
  }
}
