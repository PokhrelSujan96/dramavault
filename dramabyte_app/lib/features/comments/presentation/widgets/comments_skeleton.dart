import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentsSkeleton extends StatelessWidget {
  const CommentsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget block(double width, double height, {bool round = false}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(round ? 100 : 6.r),
          ),
        );
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 6; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(36.w, 36.w, round: true),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block(90.w, 12.h),
                    SizedBox(height: 8.h),
                    block((160 + i * 12).w, 14.h),
                    SizedBox(height: 8.h),
                    block(60.w, 10.h),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
