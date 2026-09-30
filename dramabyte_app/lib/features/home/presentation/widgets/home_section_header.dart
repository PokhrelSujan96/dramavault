import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FlareText(title).semiBold.size(17.sp),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: FlareText('See all').white.semiBold,
            ),
        ],
      ),
    );
  }
}
