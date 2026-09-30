import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_header.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_history_rail.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_rail.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_spotlight_section.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({
    super.key,
    required this.feed,
    required this.isActive,
    required this.onOpen,
  });

  final HomeFeed feed;
  final bool isActive;
  final ValueChanged<SeriesCard> onOpen;

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      for (final card in feed.trending.take(8))
        SearchSuggestion(seriesId: card.seriesId, title: card.title),
    ];
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24.h),
      children: [
        HomeHeader(suggestions: suggestions),
        HomeSearchBar(suggestions: suggestions),
        SizedBox(height: 12.h),
        if (feed.featured.isNotEmpty)
          HomeHeroCarousel(
            items: feed.featured,
            isActive: isActive,
            onOpen: onOpen,
          ),
        if (feed.trending.isNotEmpty)
          HomePosterRail(
            title: 'Trending Now',
            items: feed.trending,
            onOpen: onOpen,
          ),
        const HomeHistoryRail(),
        if (feed.trending.isNotEmpty)
          HomeSpotlightSection(
            items: feed.trending.take(8).toList(),
            onOpen: onOpen,
          ),
        for (final rail in feed.genres)
          if (rail.items.isNotEmpty)
            HomePosterRail(
              title: rail.genre,
              items: rail.items,
              onOpen: onOpen,
            ),
        SizedBox(height: 20.h),
        Divider(color: Theme.of(context).dividerColor),
        Padding(
          padding: EdgeInsetsGeometry.symmetric(
            vertical: 20.h,
            horizontal: 16.w,
          ),
          child: Column(
            children: [
              FlareText(
                'Our platform is trusted by thousands & features best ai series all around the world',
              ).xl5.extraBold.pr(30.w),
              SizedBox(height: 12.h),
              Row(
                children: [
                  FlareText('Home / ').grey,
                  FlareText('Discover / ').grey,
                  FlareText('Library / ').grey,
                  FlareText('Profile').grey,
                ],
              ),
              SizedBox(height: 20.h),
              Divider(color: Theme.of(context).dividerColor),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FlareText('Privacy policy').grey.underline,
                  FlareText('Terms of Conditions').grey.underline,
                  FlareText('Language').grey.underline,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
