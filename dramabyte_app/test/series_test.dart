import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/router/app_links.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/router/auth_redirect.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/series/data/models/series_details_model.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';
import 'package:dramabyte_app/features/series/domain/repositories/series_repository.dart';
import 'package:dramabyte_app/features/series/domain/usecases/series_use_cases.dart';
import 'package:dramabyte_app/features/series/presentation/cubit/series_details_cubit.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_episode_grid.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_range_tabs.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_sheet.dart';
import 'package:dramabyte_app/features/series/presentation/widgets/series_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

SeriesDetails series(int count, {int? free}) => SeriesDetails(
  seriesId: 's1',
  title: 'True Beauty',
  freeEpisodeCount: free,
  episodes: [
    for (var i = 1; i <= count; i++)
      EpisodeSummary(
        episodeId: 'e$i',
        episodeNumber: i,
        locked: free != null && i > free,
      ),
  ],
);

class _FakeRepository implements SeriesRepository {
  SeriesDetails? cachedValue;
  Failure? failure;
  int fetches = 0;

  @override
  Future<SeriesDetails?> cached(String seriesId) async => cachedValue;

  @override
  Future<SeriesDetails> fetch(String seriesId) async {
    fetches++;
    if (failure != null) throw failure!;
    return series(3);
  }

  @override
  Future<List<Reel>> playlist(String seriesId) async => const [];
}

void main() {
  group('details entity', () {
    test('splits episodes into ranges of 15', () {
      final ranges = series(45).ranges;
      expect(ranges.map((r) => r.label), ['1-15', '16-30', '31-45']);
      expect(series(20).ranges.last.label, '16-20');
      expect(series(1).ranges.single.label, '1');
    });

    test('labels reflect the free episode limit', () {
      expect(series(45, free: 10).freeLabel, '10 eps free');
      expect(series(45).freeLabel, isEmpty);
      expect(series(45).totalLabel, 'All 45 episodes');
    });

    test('model maps locks and survives bad rows', () {
      final details = SeriesDetailsModel({
        'series_id': 's1',
        'title': 'T',
        'free_episode_count': 1,
        'episodes': [
          {'episode_id': 'a', 'episode_number': 1},
          {'episode_id': 'b', 'episode_number': 2, 'locked': true},
          {'episode_number': 3},
          'garbage',
        ],
      }).toEntity()!;
      expect(details.episodes.map((e) => e.locked), [false, true]);
      expect(details.freeEpisodeCount, 1);
      expect(SeriesDetailsModel(const {}).toEntity(), isNull);
    });
  });

  group('deep links', () {
    test('builds custom-scheme and in-app links', () {
      expect(AppLinks.seriesPath('abc'), '/series/abc');
      expect(
        AppLinks.seriesUri('abc').toString(),
        'dramabyte://app/series/abc',
      );
    });

    test('only internal paths are accepted as a post-login target', () {
      expect(AppLinks.safeNext('/series/abc'), '/series/abc');
      expect(AppLinks.safeNext('https://evil.com'), isNull);
      expect(AppLinks.safeNext('//evil.com'), isNull);
      expect(AppLinks.safeNext('javascript:alert(1)'), isNull);
      expect(AppLinks.safeNext(null), isNull);
    });

    test('a signed-out deep link goes to login and remembers the target', () {
      final target = authRedirect(
        signedIn: false,
        matchedLocation: '/series/abc',
        uri: Uri.parse('/series/abc?x=1'),
      )!;
      final uri = Uri.parse(target);
      expect(uri.path, AppRoutes.root);
      expect(uri.queryParameters['next'], '/series/abc?x=1');
    });

    test('after login the user lands on the remembered page', () {
      String? after(String? next) => authRedirect(
        signedIn: true,
        matchedLocation: AppRoutes.root,
        uri: Uri(path: '/', queryParameters: {'next': ?next}),
      );
      expect(after('/series/abc'), '/series/abc');
      expect(after('https://evil.com'), AppRoutes.dashboard);
      expect(after(null), AppRoutes.dashboard);
    });

    test('signed-in users are never redirected away from deep links', () {
      expect(
        authRedirect(
          signedIn: true,
          matchedLocation: '/series/abc',
          uri: Uri.parse('/series/abc'),
        ),
        isNull,
      );
    });
  });

  group('details cubit', () {
    late _FakeRepository repository;
    late SeriesDetailsCubit cubit;

    setUp(() {
      repository = _FakeRepository();
      cubit = SeriesDetailsCubit(
        's1',
        GetCachedSeries(repository),
        GetSeries(repository),
      );
    });

    test('shows the cached series first, then the fresh one', () async {
      repository.cachedValue = series(2);
      final states = <ResourceState<SeriesDetails>>[];
      cubit.stream.listen(states.add);
      await cubit.load();
      expect(
        (states.first as ResourceLoaded<SeriesDetails>).value.episodeCount,
        2,
      );
      expect(
        (cubit.state as ResourceLoaded<SeriesDetails>).value.episodeCount,
        3,
      );
      expect(states.whereType<ResourceLoading<SeriesDetails>>(), isEmpty);
    });

    test('a failed refresh keeps the cached series', () async {
      repository
        ..cachedValue = series(2)
        ..failure = const NetworkFailure('offline');
      await cubit.load();
      expect(cubit.state, isA<ResourceLoaded<SeriesDetails>>());
    });

    test('a failure with nothing cached shows an error', () async {
      repository.failure = const ValidationFailure('gone');
      await cubit.load();
      expect((cubit.state as ResourceError<SeriesDetails>).message, 'gone');
    });
  });

  testWidgets('range tabs and episode grid lay out and respond', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = series(45, free: 10);
    var selected = 0;
    EpisodeSummary? tapped;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (_, setState) => ListView(
                children: [
                  SeriesRangeTabs(
                    ranges: data.ranges,
                    selected: selected,
                    onSelect: (i) => setState(() => selected = i),
                  ),
                  SeriesEpisodeGrid(
                    episodes: data.ranges[selected].episodes,
                    currentEpisodeId: 'e3',
                    onTap: (e) => tapped = e,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('1-15'), findsOneWidget);
    expect(find.text('16-30'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNWidgets(5));
    await tester.tap(find.text('7'));
    expect(tapped?.episodeNumber, 7);
    await tester.tap(find.text('16-30'));
    await tester.pump();
    expect(find.text('16'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('details sheet stays open over the backdrop and scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final data = series(45, free: 10);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.blueGrey),
                SeriesSheet(
                  children: [
                    SeriesSummary(series: data),
                    SeriesRangeTabs(
                      ranges: data.ranges,
                      selected: 0,
                      onSelect: (_) {},
                    ),
                    SeriesEpisodeGrid(
                      episodes: data.ranges.first.episodes,
                      currentEpisodeId: null,
                      onTap: (_) {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('True Beauty'), findsOneWidget);
    expect(find.text('1-15'), findsOneWidget);
    await tester.drag(find.text('True Beauty'), const Offset(0, -300));
    await tester.pump();
    expect(find.text('True Beauty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
