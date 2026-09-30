import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SeriesRangeTabs extends StatelessWidget {
  const SeriesRangeTabs({
    super.key,
    required this.ranges,
    required this.selected,
    required this.onSelect,
  });

  final List<EpisodeRange> ranges;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.sizeOf(context).width /
        (ranges.length < 3 ? ranges.length : 3);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < ranges.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(i),
              child: SizedBox(
                width: width,
                height: 48.h,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    i == selected
                        ? FlareText(ranges[i].label).semiBold
                        : FlareText(ranges[i].label).grey,
                    const Spacer(),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == selected ? 22.w : 0,
                      height: 3.h,
                      decoration: BoxDecoration(
                        color: FlareColors.primary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
