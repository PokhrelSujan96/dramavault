import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesDetailsSkeleton extends StatelessWidget {
  const SeriesDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const _Block(height: 430),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: [
              for (var i = 0; i < 10; i++)
                SizedBox(width: 58.w, height: 58.w, child: const _Block()),
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height?.h,
      decoration: BoxDecoration(
        color: context.surfaceTint,
        borderRadius: BorderRadius.circular(height == null ? 10.r : 0),
      ),
    );
  }
}
