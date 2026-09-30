import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelSkeleton extends StatelessWidget {
  const ReelSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned(
            left: 16.w,
            bottom: 32.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Block(width: 180.w, height: 20.h),
                SizedBox(height: 10.h),
                _Block(width: 260.w, height: 12.h),
                SizedBox(height: 6.h),
                _Block(width: 220.w, height: 12.h),
              ],
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 40.h,
            child: Column(
              children: [
                for (var i = 0; i < 4; i++) ...[
                  _Block(width: 32.w, height: 32.w, radius: 16.r),
                  SizedBox(height: 18.h),
                ],
              ],
            ),
          ),
          const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.width, required this.height, this.radius = 6});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
