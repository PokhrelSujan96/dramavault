import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_poster_card.dart';
import 'package:dramabyte_app/features/home/presentation/widgets/home_spotlight_section.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

import 'library_test.dart' show FakeLibraryHandle, buildCubit;

SeriesCard card(int i, {int views = 0, int? free}) => SeriesCard(
  seriesId: 's$i',
  title: 'Series $i',
  description: 'About series $i',
  genre: 'Thriller',
  episodeCount: 10 + i,
  freeEpisodeCount: free,
  views: views,
);

void main() {
  late FakeLibraryHandle repository;
  late LibraryCubit library;

  setUp(() async {
    repository = FakeLibraryHandle();
    library = buildCubit(repository);
    await Future<void>.delayed(const Duration(milliseconds: 30));
  });

  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: BlocProvider.value(
        value: library,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('poster card shows the series view count', (tester) async {
    await tester.pumpWidget(
      host(HomePosterCard(card: card(1, views: 1250000), onTap: () {})),
    );
    expect(find.text('1.25M views'), findsOneWidget);
    expect(find.text('0 views'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spotlight shows the first series and lets you pick another', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final opened = <String>[];
    await tester.pumpWidget(
      host(
        HomeSpotlightSection(
          items: [card(11, views: 3000), card(12), card(13)],
          onOpen: (c) => opened.add(c.seriesId),
        ),
      ),
    );
    expect(find.text('Featured in DramaByte'), findsOneWidget);
    expect(find.text('#1 Trending'), findsOneWidget);
    expect(find.text('Thriller · 21 episodes · 3K views'), findsOneWidget);
    expect(find.text('Play Now'), findsOneWidget);
    expect(find.text('Add to Library'), findsOneWidget);

    await tester.tap(find.text('Series 12').last);
    await tester.pumpAndSettle();
    expect(find.text('#2 Trending'), findsOneWidget);
    expect(opened, isEmpty);

    await tester.tap(find.text('Play Now'));
    expect(opened, ['s12']);
    await tester.tap(find.text('Series 12').last);
    expect(opened, ['s12', 's12']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add to library saves the featured series instantly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      host(HomeSpotlightSection(items: [card(7), card(8)], onOpen: (_) {})),
    );
    expect(library.isSaved('s7'), isFalse);
    await tester.tap(find.text('Add to Library'));
    await tester.pump();
    expect(library.isSaved('s7'), isTrue);
    expect(find.text('Saved'), findsOneWidget);
    expect(repository.calls, ['add:s7']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spotlight fits very narrow phones with long titles', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const long = SeriesCard(
      seriesId: 's99',
      title:
          'An Extremely Long Series Title That Keeps Going And Going Forever',
      description:
          'A very long description that should never overflow the section even '
          'when the phone is very narrow and the text wraps several times.',
      genre: 'Romantic Comedy',
      episodeCount: 120,
      views: 12345678,
    );
    await tester.pumpWidget(
      host(HomeSpotlightSection(items: const [long, long], onOpen: (_) {})),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
