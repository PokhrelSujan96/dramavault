import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelActionButton extends StatelessWidget {
  const ReelActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.only(top: 5.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              icon,
              SizedBox(height: 4.h),
              FlareText(label).xs.white.semiBold,
            ],
          ),
        ),
      ),
    );
  }
}
