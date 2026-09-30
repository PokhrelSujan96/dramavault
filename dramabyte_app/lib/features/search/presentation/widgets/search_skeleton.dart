import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                _Block(width: 56.w, height: 84.h),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Block(width: 160.w, height: 16.h),
                    SizedBox(height: 8.h),
                    _Block(width: 100.w, height: 12.h),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.surfaceTint,
        borderRadius: BorderRadius.circular(8.r),
      ),
    );
  }
}
