import 'dart:async';

import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/search/data/datasources/search_local_source.dart';
import 'package:dramabyte_app/features/search/data/models/search_result_model.dart';
import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';
import 'package:dramabyte_app/features/search/domain/repositories/search_repository.dart';
import 'package:dramabyte_app/features/search/domain/usecases/search_use_cases.dart';
import 'package:dramabyte_app/features/search/presentation/cubit/search_cubit.dart';
import 'package:dramabyte_app/features/search/presentation/pages/search_page.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_highlighted_text.dart';
import 'package:dramabyte_app/features/search/presentation/widgets/search_open_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

SearchResult result(String name) =>
    SearchResult(seriesId: name, title: name, genre: 'Drama', episodeCount: 5);

class _FakeRepository implements SearchRepository {
  final calls = <String>[];
  final completers = <String, Completer<List<SearchResult>>>{};
  Failure? failure;
  var stored = <String>[];

  @override
  Future<List<SearchResult>> search(String query) {
    calls.add(query);
    if (failure != null) return Future.error(failure!);
    return completers[query]?.future ?? Future.value([result(query)]);
  }

  @override
  Future<List<String>> recents() async => List.of(stored);

  @override
  Future<void> saveRecent(String query) async =>
      stored = [query, ...stored.where((e) => e != query)];

  @override
  Future<void> removeRecent(String query) async =>
      stored = stored.where((e) => e != query).toList();

  @override
  Future<void> clearRecents() async => stored = [];
}

SearchCubit _build(_FakeRepository repository) => SearchCubit(
  SearchSeries(repository),
  GetRecentSearches(repository),
  SaveRecentSearch(repository),
  RemoveRecentSearch(repository),
  ClearRecentSearches(repository),
  debounce: const Duration(milliseconds: 20),
);

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late _FakeRepository repository;
  late SearchCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = _build(repository);
  });

  group('search cubit', () {
    test(
      'queries shorter than 2 characters stay idle and never search',
      () async {
        cubit.onQueryChanged('a');
        await settle();
        expect(cubit.state.status, SearchStatus.idle);
        expect(repository.calls, isEmpty);
      },
    );

    test('debounces fast typing into a single request', () async {
      for (final text in ['lo', 'lov', 'love']) {
        cubit.onQueryChanged(text);
      }
      await settle();
      expect(repository.calls, ['love']);
      expect(cubit.state.status, SearchStatus.loaded);
      expect(cubit.state.results.single.title, 'love');
    });

    test('a slow older response never overwrites a newer one', () async {
      repository.completers['ab'] = Completer();
      cubit.onQueryChanged('ab');
      await settle();
      cubit.onQueryChanged('abc');
      await settle();
      repository.completers['ab']!.complete([result('stale')]);
      await settle();
      expect(cubit.state.query, 'abc');
      expect(cubit.state.results.single.title, 'abc');
    });

    test('repeating a query is answered instantly from memory', () async {
      cubit.onQueryChanged('love');
      await settle();
      cubit.onQueryChanged('lo');
      cubit.onQueryChanged('love');
      expect(cubit.state.status, SearchStatus.loaded);
      await settle();
      expect(repository.calls, ['love']);
    });

    test('keeps showing old results while a new search loads', () async {
      cubit.onQueryChanged('love');
      await settle();
      repository.completers['lovex'] = Completer();
      cubit.onQueryChanged('lovex');
      expect(cubit.state.status, SearchStatus.loading);
      expect(cubit.state.results, isNotEmpty);
    });

    test('failure shows an error and retry recovers', () async {
      repository.failure = const NetworkFailure('offline');
      cubit.onQueryChanged('love');
      await settle();
      expect(cubit.state.status, SearchStatus.failure);
      expect(cubit.state.error, 'offline');
      repository.failure = null;
      await cubit.retry();
      expect(cubit.state.status, SearchStatus.loaded);
    });

    test('submit and select save recents without duplicates', () async {
      await cubit.submit('love');
      await cubit.submit('story');
      await cubit.select(result('Love Story'));
      expect(cubit.state.recents.first, 'story');
      await cubit.removeRecent('story');
      expect(cubit.state.recents, ['love']);
      await cubit.clearRecents();
      expect(cubit.state.recents, isEmpty);
    });
  });

  group('recent searches storage', () {
    late SearchLocalSource local;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      local = SearchLocalSource(await SharedPreferences.getInstance());
    });

    test(
      'most recent first, deduped case-insensitively, capped at 8',
      () async {
        await local.save('Love');
        await local.save('love');
        expect(local.recents(), ['love']);
        for (var i = 0; i < 12; i++) {
          await local.save('q$i');
        }
        expect(local.recents().length, SearchLocalSource.maxRecents);
        expect(local.recents().first, 'q11');
      },
    );

    test('ignores blanks, removes and clears', () async {
      await local.save('   ');
      expect(local.recents(), isEmpty);
      await local.save('a1');
      await local.save('b2');
      await local.remove('a1');
      expect(local.recents(), ['b2']);
      await local.clear();
      expect(local.recents(), isEmpty);
    });
  });

  test('model skips rows without an id and tolerates bad types', () {
    expect(SearchResultModel(const {'title': 'x'}).toEntity(), isNull);
    final entity = SearchResultModel(const {
      'series_id': 's1',
      'title': 'T',
      'episode_count': 'oops',
      'free_episode_count': 4,
    }).toEntity()!;
    expect(entity.episodeCount, 0);
    expect(entity.subtitle, '4 eps free');
    expect(result('a').subtitle, 'Drama · 5 episodes');
  });

  testWidgets('highlights the matching part of a title', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: SearchHighlightedText(text: 'True Beauty', query: 'beau'),
        ),
      ),
    );
    final spans = (tester.widget<Text>(find.byType(Text)).textSpan! as TextSpan)
        .children!
        .cast<TextSpan>();
    expect(spans.map((s) => s.text), ['True ', 'Beau', 'ty']);
  });

  testWidgets('container transform opens the search page and closes again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await getIt.reset();
    getIt.registerFactory(() => _build(repository));
    addTearDown(getIt.reset);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: SearchOpenContainer(
                closedColor: Colors.black,
                closedShape: const RoundedRectangleBorder(),
                closedBuilder: (_) => const SizedBox(
                  width: 300,
                  height: 48,
                  child: Center(child: Text('Search dramas or series')),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(SearchPage), findsNothing);
    await tester.tap(find.text('Search dramas or series'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SearchPage), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'love');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('love'), findsWidgets);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsNothing);
    expect(find.text('Search dramas or series'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
