import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentsErrorView extends StatelessWidget {
  const CommentsErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlareText(message).grey.center.pb(12.h),
            FlareButton(label: 'Try again', expand: false, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
