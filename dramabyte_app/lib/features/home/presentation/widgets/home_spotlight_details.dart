import 'package:dramabyte_app/components/flare_glass_button.dart';
import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_library_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeSpotlightDetails extends StatelessWidget {
  const HomeSpotlightDetails({
    super.key,
    required this.card,
    required this.rank,
    required this.onPlay,
  });

  final SeriesCard card;
  final int rank;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (card.rating.hasRatings) '★ ${card.rating.averageLabel}',
      if (card.genre.isNotEmpty) card.genre,
      card.episodesLabel,
      card.viewsLabel,
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(100.r),
          ),
          child: FlareText('#$rank Trending').xs.semiBold.white,
        ),
        SizedBox(height: 12.h),
        FlareText(card.title).xl4.bold.white.setMaxLines(2).ellipsis,
        SizedBox(height: 6.h),
        FlareText(meta).sm.setColor(Colors.white70),
        if (card.description.isNotEmpty) ...[
          SizedBox(height: 10.h),
          FlareText(card.description).sm
              .setColor(Colors.white70)
              .readMore_
              .setReadMoreMaxLines(3)
              .setReadMoreText('Read more')
              .setReadLessText('Show less')
              .setReadMoreColor(Colors.white),
        ],
        SizedBox(height: 16.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 10.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FlareGlassButton(
              label: 'Play Now',
              icon: FlareSvgIcon('play', size: 16.sp, color: Colors.white),
              onPressed: onPlay,
            ),
            HomeLibraryButton(card: card),
          ],
        ),
      ],
    );
  }
}
