import 'dart:async';

import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_rating_button.dart';
import 'package:dramabyte_app/features/home/data/models/home_models.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_card.dart';
import 'package:dramabyte_app/features/ratings/data/models/rating_summary_model.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/ratings/domain/repositories/rating_repository.dart';
import 'package:dramabyte_app/features/ratings/domain/usecases/rating_use_cases.dart';
import 'package:dramabyte_app/features/ratings/presentation/cubit/ratings_cubit.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_badge.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_sheet.dart';
import 'package:dramabyte_app/features/ratings/presentation/widgets/rating_stars.dart';
import 'package:dramabyte_app/features/series/data/models/series_details_model.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_rating_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeServer implements RatingRepository {
  int sum = 25;
  int count = 3;
  int? mine;
  final calls = <String>[];
  Failure? failure;
  Completer<void>? gate;

  RatingSummary get summary => RatingSummary(
    average: count == 0 ? null : double.parse((sum / count).toStringAsFixed(1)),
    count: count,
    myRating: mine,
  );

  @override
  Future<RatingSummary> rate(RatingTarget target, String id, int rating) async {
    calls.add('rate:${target.name}:$id:$rating');
    await gate?.future;
    if (failure != null) throw failure!;
    if (mine != null) {
      sum -= mine!;
    } else {
      count += 1;
    }
    sum += rating;
    mine = rating;
    return summary;
  }

  @override
  Future<RatingSummary> clear(RatingTarget target, String id) async {
    calls.add('clear:${target.name}:$id');
    await gate?.future;
    if (failure != null) throw failure!;
    if (mine != null) {
      sum -= mine!;
      count -= 1;
      mine = null;
    }
    return summary;
  }
}

RatingsCubit buildCubit(FakeServer server) =>
    RatingsCubit(RateTitle(server), ClearRating(server));

void main() {
  group('summary maths', () {
    test('labels', () {
      const s = RatingSummary(average: 8.44, count: 1250);
      expect(s.averageLabel, '8.4');
      expect(s.countLabel, '1.25K');
      expect(s.hasRatings, isTrue);
      expect(const RatingSummary().hasRatings, isFalse);
      expect(const RatingSummary().averageLabel, '');
    });

    test('a first rating adds a vote and shifts the average', () {
      final next = const RatingSummary(average: 8, count: 2).withMine(10);
      expect((next.average, next.count, next.myRating), (8.7, 3, 10));
    });

    test('changing a rating replaces it without adding a vote', () {
      final base = const RatingSummary(average: 8, count: 2).withMine(10);
      final changed = base.withMine(4);
      expect((changed.average, changed.count, changed.myRating), (6.7, 3, 4));
    });

    test('removing a rating takes the vote back out', () {
      final rated = const RatingSummary(average: 8, count: 2).withMine(10);
      final cleared = rated.withMine(null);
      expect(
        (cleared.average, cleared.count, cleared.myRating),
        (8.0, 2, null),
      );
      final only = const RatingSummary().withMine(7).withMine(null);
      expect((only.average, only.count), (null, 0));
    });
  });

  group('parsing', () {
    test('rating summary model is tolerant', () {
      final model = RatingSummaryModel(const {
        'average': 8.5,
        'count': 'x',
        'my_rating': 9,
      }).toEntity();
      expect((model.average, model.count, model.myRating), (8.5, 0, 9));
      expect(RatingSummaryModel(const {}).toEntity(), const RatingSummary());
    });

    test('reel, series details and home cards read their ratings', () {
      final reel = ReelModel(const {
        'episode_id': 'e1',
        'rating_average': 7.9,
        'rating_count': 40,
        'my_rating': 8,
      }).toEntity()!;
      expect(
        reel.rating,
        const RatingSummary(average: 7.9, count: 40, myRating: 8),
      );
      final details = SeriesDetailsModel(const {
        'series_id': 's1',
        'rating_average': 9.1,
        'rating_count': 12,
      }).toEntity()!;
      expect(details.rating.average, 9.1);
      final feed = HomeFeedModel(const {
        'featured': [
          {'series_id': 's1', 'rating_average': 8.2, 'rating_count': 5},
        ],
      }).toEntity();
      expect(feed.featured.single.rating.count, 5);
      expect(feed.featured.single.rating.myRating, isNull);
    });
  });

  group('ratings cubit', () {
    late FakeServer server;
    late RatingsCubit cubit;

    setUp(() {
      server = FakeServer();
      cubit = buildCubit(server);
    });

    test('rating is optimistic and then reconciled with the server', () async {
      cubit.seed(RatingTarget.series, 's1', server.summary);
      server.gate = Completer();
      final future = cubit.rate(RatingTarget.series, 's1', 10);
      final shown = cubit.state.of(RatingTarget.series, 's1')!;
      expect((shown.average, shown.count, shown.myRating), (8.7, 4, 10));
      server.gate!.complete();
      expect(await future, isNull);
      final done = cubit.state.of(RatingTarget.series, 's1')!;
      expect((done.average, done.count, done.myRating), (8.8, 4, 10));
    });

    test('a rejected rating rolls back and explains why', () async {
      cubit.seed(RatingTarget.episode, 'e1', server.summary);
      server.failure = const ValidationFailure('You are rating too fast');
      final error = await cubit.rate(RatingTarget.episode, 'e1', 9);
      expect(error, 'You are rating too fast');
      expect(cubit.state.of(RatingTarget.episode, 'e1'), server.summary);
    });

    test('clearing removes my rating and the vote', () async {
      cubit.seed(RatingTarget.series, 's1', server.summary);
      await cubit.rate(RatingTarget.series, 's1', 10);
      expect(await cubit.clear(RatingTarget.series, 's1'), isNull);
      final s = cubit.state.of(RatingTarget.series, 's1')!;
      expect((s.count, s.myRating), (3, null));
      expect(server.calls.last, 'clear:series:s1');
    });

    test(
      'rapid changes end on the latest choice with no lost update',
      () async {
        cubit.seed(RatingTarget.series, 's1', server.summary);
        server.gate = Completer();
        final first = cubit.rate(RatingTarget.series, 's1', 4);
        final second = cubit.rate(RatingTarget.series, 's1', 9);
        expect(cubit.state.of(RatingTarget.series, 's1')!.myRating, 9);
        server.gate!.complete();
        await first;
        await second;
        expect(cubit.state.of(RatingTarget.series, 's1')!.myRating, 9);
        expect(server.mine, 9);
        expect(server.calls.last, endsWith(':9'));
      },
    );

    test('seeding never overwrites a rating that is being saved', () async {
      cubit.seed(RatingTarget.series, 's1', server.summary);
      server.gate = Completer();
      final future = cubit.rate(RatingTarget.series, 's1', 10);
      cubit.seed(
        RatingTarget.series,
        's1',
        const RatingSummary(average: 5, count: 1),
      );
      expect(cubit.state.of(RatingTarget.series, 's1')!.myRating, 10);
      server.gate!.complete();
      await future;
    });

    test('series and episodes are tracked independently', () async {
      await cubit.rate(RatingTarget.series, 'x', 6);
      await cubit.rate(RatingTarget.episode, 'x', 3);
      expect(cubit.state.of(RatingTarget.series, 'x')!.myRating, 6);
      expect(cubit.state.of(RatingTarget.episode, 'x')!.myRating, 3);
    });

    test('seeding reels sets each episode rating', () {
      cubit.seedReels(const [
        Reel(
          episodeId: 'e1',
          seriesId: 's',
          title: 'T',
          rating: RatingSummary(average: 7, count: 3, myRating: 5),
        ),
      ]);
      expect(cubit.state.of(RatingTarget.episode, 'e1')!.myRating, 5);
    });
  });

  group('widgets', () {
    late FakeServer server;
    late RatingsCubit cubit;

    setUp(() {
      server = FakeServer();
      cubit = buildCubit(server);
    });

    Widget host(Widget child, {double width = 390}) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

    testWidgets('stars: tap and slide select 1 to 10', (tester) async {
      int? value;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (_, setState) => RatingStars(
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(RatingStars));
      await tester.tapAt(Offset(rect.left + rect.width * 0.75, rect.center.dy));
      await tester.pump();
      expect(value, 8);
      await tester.dragFrom(
        Offset(rect.left + rect.width * 0.75, rect.center.dy),
        Offset(-rect.width * 0.5, 0),
      );
      await tester.pump();
      expect(value, lessThan(8));
      await tester.tapAt(Offset(rect.right - 1, rect.center.dy));
      await tester.pump();
      expect(value, 10);
    });

    testWidgets('badge shows the score, scale and vote count', (tester) async {
      await tester.pumpWidget(
        host(
          const RatingBadge(summary: RatingSummary(average: 8.4, count: 12000)),
        ),
      );
      expect(find.text('8.4'), findsOneWidget);
      expect(find.text('/10'), findsOneWidget);
      expect(find.text('(12K)'), findsOneWidget);
      await tester.pumpWidget(
        host(const RatingBadge(summary: RatingSummary())),
      );
      expect(find.text('No ratings yet'), findsOneWidget);
    });

    testWidgets('sheet: pick a score, rate, and see it instantly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      cubit.seed(RatingTarget.series, 's1', server.summary);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showRatingSheet(
                context,
                target: RatingTarget.series,
                id: 's1',
                title: 'True Beauty',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Rate this series'), findsOneWidget);
      expect(find.text('True Beauty'), findsOneWidget);
      expect(find.text('Tap or slide across the stars'), findsOneWidget);
      final stars = tester.getRect(find.byType(RatingStars));
      await tester.tapAt(
        Offset(stars.left + stars.width * 0.85, stars.center.dy),
      );
      await tester.pump();
      expect(find.text('9 / 10'), findsOneWidget);
      await tester.tap(find.text('Rate 9'));
      await tester.pumpAndSettle();
      expect(cubit.state.of(RatingTarget.series, 's1')!.myRating, 9);
      expect(find.text('You rated this 9/10'), findsOneWidget);
      expect(server.calls, ['rate:series:s1:9']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sheet: an existing rating can be removed', (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await cubit.rate(RatingTarget.episode, 'e1', 6);
      server.calls.clear();
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showRatingSheet(
                context,
                target: RatingTarget.episode,
                id: 'e1',
                title: 'Ep 1',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('6 / 10'), findsOneWidget);
      expect(find.text('Update rating'), findsOneWidget);
      await tester.tap(find.text('Remove rating'));
      await tester.pumpAndSettle();
      expect(cubit.state.of(RatingTarget.episode, 'e1')!.myRating, isNull);
      expect(find.text('Rating removed'), findsOneWidget);
      expect(server.calls, ['clear:episode:e1']);
    });

    testWidgets('sheet: a failed save shows the reason and rolls back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      server.failure = const NetworkFailure('Could not save your rating.');
      cubit.seed(RatingTarget.series, 's1', server.summary);
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showRatingSheet(
                context,
                target: RatingTarget.series,
                id: 's1',
                title: 'T',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final stars = tester.getRect(find.byType(RatingStars));
      await tester.tapAt(
        Offset(stars.left + stars.width * 0.55, stars.center.dy),
      );
      await tester.pump();
      await tester.tap(find.text('Rate 6'));
      await tester.pumpAndSettle();
      expect(find.text('Could not save your rating.'), findsOneWidget);
      expect(cubit.state.of(RatingTarget.series, 's1')!.myRating, isNull);
    });

    testWidgets('series page row shows the average and your own rating', (
      tester,
    ) async {
      const series = SeriesDetails(
        seriesId: 's1',
        title: 'True Beauty',
        episodes: [],
        rating: RatingSummary(average: 8.4, count: 320),
      );
      cubit.seed(RatingTarget.series, 's1', series.rating);
      await tester.pumpWidget(host(const SeriesRatingRow(series: series)));
      expect(find.text('8.4'), findsOneWidget);
      expect(find.text('Rate'), findsOneWidget);
      await cubit.rate(RatingTarget.series, 's1', 7);
      await tester.pump();
      expect(find.text('Your rating: 7'), findsOneWidget);
    });

    testWidgets('reel button shows the average, then my score', (tester) async {
      const reel = Reel(
        episodeId: 'e1',
        seriesId: 's',
        title: 'T',
        rating: RatingSummary(average: 7.3, count: 9),
      );
      cubit.seedReels([reel]);
      await tester.pumpWidget(
        host(
          const ColoredBox(
            color: Colors.black,
            child: ReelRatingButton(reel: reel),
          ),
        ),
      );
      expect(find.text('7.3'), findsOneWidget);
      await cubit.rate(RatingTarget.episode, 'e1', 9);
      await tester.pumpAndSettle();
      expect(find.text('9/10'), findsOneWidget);
    });

    testWidgets('a reel with no ratings invites the first one', (tester) async {
      const reel = Reel(episodeId: 'e2', seriesId: 's', title: 'T');
      await tester.pumpWidget(
        host(
          const ColoredBox(
            color: Colors.black,
            child: ReelRatingButton(reel: reel),
          ),
        ),
      );
      expect(find.text('Rate'), findsOneWidget);
    });

    testWidgets('home card shows the rating only when there is one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const rated = SeriesCard(
        seriesId: 's1',
        title: 'Rated',
        rating: RatingSummary(average: 9.0, count: 200),
      );
      const plain = SeriesCard(seriesId: 's2', title: 'Plain');
      await tester.pumpWidget(
        host(
          Row(
            children: [
              HomePosterCard(card: rated, onTap: () {}),
              HomePosterCard(card: plain, onTap: () {}),
            ],
          ),
        ),
      );
      expect(find.text('9.0'), findsOneWidget);
      expect(find.text('(200)'), findsOneWidget);
      expect(find.byType(RatingBadge), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the home card overlay reflects a rating you just gave', (
      tester,
    ) async {
      const card = SeriesCard(
        seriesId: 's1',
        title: 'Show',
        rating: RatingSummary(average: 8.0, count: 2),
      );
      server
        ..sum = 16
        ..count = 2;
      cubit.seed(RatingTarget.series, 's1', card.rating);
      await tester.pumpWidget(host(HomePosterCard(card: card, onTap: () {})));
      expect(find.text('8.0'), findsOneWidget);
      await cubit.rate(RatingTarget.series, 's1', 10);
      await tester.pump();
      expect(find.text('8.7'), findsOneWidget);
    });
  });
}
