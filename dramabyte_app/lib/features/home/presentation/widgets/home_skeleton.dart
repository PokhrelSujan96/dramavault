import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width * 0.3;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        const HomeHeader(),
        _Block(
          height: 230.h,
          margin: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        SizedBox(height: 24.h),
        _Block(
          height: 18.h,
          width: 120.w,
          margin: EdgeInsets.only(left: 16.w),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Row(
            spacing: 12,
            children: [
              for (var i = 0; i < 3; i++)
                _Block(height: width * 1.5, width: width),
            ],
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height, this.width, this.margin});

  final double height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      margin: margin,
      decoration: BoxDecoration(
        color: context.surfaceTint,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }
}
