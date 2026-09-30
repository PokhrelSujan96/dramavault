import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelOfflineChip extends StatelessWidget {
  const ReelOfflineChip({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(top: 8.h),
        child: GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off, size: 14.sp, color: Colors.white),
                SizedBox(width: 6.w),
                FlareText(
                  'Offline · showing saved episodes. Tap to retry',
                ).xs.white,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
