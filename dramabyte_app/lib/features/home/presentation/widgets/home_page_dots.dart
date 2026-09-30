import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePageDots extends StatelessWidget {
  const HomePageDots({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: EdgeInsets.symmetric(horizontal: 3.w),
            width: i == index ? 18.w : 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: i == index ? FlareColors.background : Colors.grey,
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
      ],
    );
  }
}
