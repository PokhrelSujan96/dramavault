import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelStatusView extends StatelessWidget {
  const ReelStatusView({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
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
            Icon(icon, size: 44.sp, color: Colors.white54),
            SizedBox(height: 12.h),
            FlareText(message).white.center.pb(16.h),
            if (actionLabel != null)
              FlareButton(
                label: actionLabel!,
                expand: false,
                onPressed: onAction,
              ),
          ],
        ),
      ),
    );
  }
}
