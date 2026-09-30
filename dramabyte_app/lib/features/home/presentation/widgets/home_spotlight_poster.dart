import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSpotlightPoster extends StatelessWidget {
  const HomeSpotlightPoster({
    super.key,
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final SeriesCard card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1 : 0.94,
        duration: const Duration(milliseconds: 220),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: MediaQuery.sizeOf(context).width * 0.36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? FlareColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FlareNetworkImage(card.thumbnailUrl, cacheWidth: 420),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.center,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10.w,
                    right: 10.w,
                    bottom: 10.h,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FlareText(
                          card.title,
                        ).sm.bold.white.setMaxLines(1).ellipsis,
                        SizedBox(height: 2.h),
                        FlareText(
                          card.subtitle,
                        ).xs.setColor(Colors.white70).setMaxLines(1).ellipsis,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
