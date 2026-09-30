import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LibraryEmptyView extends StatelessWidget {
  const LibraryEmptyView({super.key, required this.onExplore});

  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlareSvgIcon('bookmark_outline', size: 64.sp, color: Colors.grey),
            SizedBox(height: 16.h),
            FlareText('Your library is empty').xl.semiBold.center,
            FlareText(
              'Tap the bookmark on any series to save it for later.',
            ).sm.grey.center.pt(6.h),
            SizedBox(height: 20.h),
            FlareButton(
              label: 'Explore series',
              expand: false,
              onPressed: onExplore,
            ),
          ],
        ),
      ),
    );
  }
}
