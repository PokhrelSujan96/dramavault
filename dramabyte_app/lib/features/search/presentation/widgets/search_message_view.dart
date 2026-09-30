import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SearchMessageView extends StatelessWidget {
  const SearchMessageView({
    super.key,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44.sp, color: Colors.grey),
            SizedBox(height: 12.h),
            FlareText(title).lg.semiBold.center,
            if (message != null) FlareText(message!).sm.grey.center.pt(6.h),
            if (actionLabel != null) ...[
              SizedBox(height: 16.h),
              FlareButton(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
