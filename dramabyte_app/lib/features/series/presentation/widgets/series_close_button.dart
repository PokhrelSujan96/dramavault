import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class SeriesCloseButton extends StatelessWidget {
  const SeriesCloseButton({super.key});

  void _close(BuildContext context) => context.canPop()
      ? context.pop()
      : context.goNamed(AppRoutes.dashboardName);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: GestureDetector(
          onTap: () => _close(context),
          child: Container(
            width: 40.w,
            height: 40.w,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black45,
            ),
            child: Icon(Icons.close, size: 20.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
