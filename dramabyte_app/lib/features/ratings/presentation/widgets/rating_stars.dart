import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  int _at(double dx, double width) => ((dx / width) * 10).ceil().clamp(1, 10);

  void _select(double dx, double width) {
    final next = _at(dx, width);
    if (next == value) return;
    HapticFeedback.selectionClick();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      slider: true,
      label: 'Your rating',
      value: value == null ? 'not rated' : '$value out of 10',
      increasedValue: '${((value ?? 0) + 1).clamp(1, 10)}',
      decreasedValue: '${((value ?? 2) - 1).clamp(1, 10)}',
      onIncrease: () => onChanged(((value ?? 0) + 1).clamp(1, 10)),
      onDecrease: () => onChanged(((value ?? 2) - 1).clamp(1, 10)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _select(d.localPosition.dx, width),
            onHorizontalDragStart: (d) => _select(d.localPosition.dx, width),
            onHorizontalDragUpdate: (d) => _select(d.localPosition.dx, width),
            child: SizedBox(
              height: 44.h,
              child: Row(
                children: [
                  for (var i = 1; i <= 10; i++)
                    Expanded(
                      child: AnimatedScale(
                        scale: i == value ? 1.2 : 1,
                        duration: const Duration(milliseconds: 120),
                        child: Icon(
                          (value ?? 0) >= i
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 30.sp,
                          color: (value ?? 0) >= i
                              ? RatingColors.gold
                              : Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
