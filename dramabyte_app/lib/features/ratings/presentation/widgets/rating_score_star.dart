import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingScoreStar extends StatelessWidget {
  const RatingScoreStar({super.key, required this.value});

  final int? value;

  @override
  Widget build(BuildContext context) {
    final size = 96.sp;
    return AnimatedScale(
      scale: value == null ? 0.92 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              size: size,
              color: value == null ? Colors.grey.shade400 : RatingColors.gold,
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: FlareText(
                value?.toString() ?? '?',
              ).size(30).extraBold.setColor(Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
