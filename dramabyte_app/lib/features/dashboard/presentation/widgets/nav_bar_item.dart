import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String icon;
  final String activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: Semantics(
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: onTap,
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          focusColor: Colors.transparent,
          borderRadius: BorderRadius.circular(0.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 8.h),
                AnimatedScale(
                  scale: isSelected ? 1 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: FlareSvgIcon(
                    isSelected ? activeIcon : icon,
                    size: 20.sp,
                    color: color,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  label,
                  style: TextStyle(fontSize: 11.sp, color: color),
                ),
                SizedBox(height: 5.h),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 20.w : 0,
                  height: 3.h,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
