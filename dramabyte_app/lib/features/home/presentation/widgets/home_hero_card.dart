import 'package:dramabyte_app/components/flare_glass_button.dart';
import 'package:dramabyte_app/components/flare_network_image.dart';
import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({super.key, required this.card, required this.onPlay});

  final SeriesCard card;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (card.genre.isNotEmpty) card.genre,
      card.episodesLabel,
    ].join(' · ');
    return GestureDetector(
      onTap: onPlay,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlareNetworkImage(card.thumbnailUrl, cacheWidth: 900),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
              ),
              Container(
                width: MediaQuery.of(context).size.width.w,
                height: MediaQuery.of(context).size.height.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlareText(
                      card.title,
                    ).xl2.bold.white.setMaxLines(1).ellipsis,
                    SizedBox(height: 2.h),
                    FlareText(subtitle).sm.setColor(Colors.white70),
                    SizedBox(height: 10.h),
                    FlareGlassButton(
                      label: 'Play Now',
                      icon: FlareSvgIcon(
                        'play',
                        size: 16.sp,
                        color: Colors.white,
                      ),
                      onPressed: onPlay,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
