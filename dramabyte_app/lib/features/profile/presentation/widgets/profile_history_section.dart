import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/history/presentation/widgets/history_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProfileHistorySection extends StatelessWidget {
  const ProfileHistorySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FlareText('History').xl,
              IconButton(
                onPressed: () => context.pushNamed(AppRoutes.historyName),
                icon: Icon(MdiIcons.chevronRight, color: Colors.grey),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        const HistoryStrip(),
      ],
    );
  }
}
