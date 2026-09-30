import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HistoryPlaceholderTile extends StatelessWidget {
  const HistoryPlaceholderTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.3,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: context.surfaceTint,
          ),
        ),
      ),
    );
  }
}
