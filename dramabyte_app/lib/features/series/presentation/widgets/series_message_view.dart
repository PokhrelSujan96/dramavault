import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesMessageView extends StatelessWidget {
  const SeriesMessageView({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlareText(message).grey.center.pb(12.h),
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
