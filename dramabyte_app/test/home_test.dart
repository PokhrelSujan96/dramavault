import 'package:dramabyte_app/features/home/data/models/home_models.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_rail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

SeriesCard card(int i) => SeriesCard(
  seriesId: 's$i',
  title: 'A very long series title number $i that must not overflow',
  genre: 'Thriller',
  episodeCount: i,
);

void main() {
  test('model maps a full payload', () {
    final feed = HomeFeedModel({
      'featured': [
        {'series_id': 'a', 'title': 'A', 'episode_count': 9},
      ],
      'trending': [
        {'series_id': 'b', 'title': 'B'},
      ],
      'genres': [
        {
          'genre': 'Love Story',
          'items': [
            {'series_id': 'c', 'title': 'C'},
          ],
        },
      ],
    }).toEntity();
    expect(feed.featured.single.episodesLabel, '9 episodes');
    expect(feed.genres.single.genre, 'Love Story');
    expect(feed.isEmpty, isFalse);
  });

  test('model survives missing sections, bad rows and wrong types', () {
    final feed = HomeFeedModel({
      'featured': 'nope',
      'trending': [
        {'title': 'no id'},
        42,
      ],
      'genres': [
        {'genre': '', 'items': []},
        'garbage',
        {'genre': 'Action', 'items': null},
      ],
    }).toEntity();
    expect(feed.featured, isEmpty);
    expect(feed.trending, isEmpty);
    expect(feed.genres.single.items, isEmpty);
    expect(feed.isEmpty, isTrue);
  });

  test('card subtitle prefers the free episode count', () {
    const paid = SeriesCard(
      seriesId: 'a',
      title: 'A',
      episodeCount: 12,
      freeEpisodeCount: 10,
    );
    const open = SeriesCard(seriesId: 'b', title: 'B', episodeCount: 12);
    expect(paid.subtitle, '10 eps free');
    expect(open.subtitle, '12 episodes');
    final parsed = HomeFeedModel({
      'featured': [
        {'series_id': 'a', 'title': 'A', 'free_episode_count': 10},
        {'series_id': 'b', 'title': 'B', 'free_episode_count': 'x'},
      ],
    }).toEntity();
    expect(parsed.featured[0].freeEpisodeCount, 10);
    expect(parsed.featured[1].freeEpisodeCount, isNull);
  });

  test('singular episode label', () {
    expect(card(1).episodesLabel, '1 episode');
  });

  testWidgets('hero carousel and poster rail lay out without errors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                HomeHeroCarousel(
                  items: [card(1), card(2), card(3)],
                  isActive: true,
                  onOpen: (_) {},
                ),
                HomePosterRail(
                  title: 'Trending Now',
                  items: [for (var i = 1; i <= 8; i++) card(i)],
                  onOpen: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    expect(find.text('Trending Now'), findsOneWidget);
  });

  testWidgets('poster image matches the watch history card size', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: HomePosterCard(card: card(1), onTap: () {}),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final image = tester.getSize(find.byType(AspectRatio));
    expect(image.width, closeTo(390 * 0.3, 0.1));
    expect(image.height, closeTo(390 * 0.3 * 1.5, 0.1));
  });
}
