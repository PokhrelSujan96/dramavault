import 'dart:async';

import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dramabyte_app/features/authentication/domain/usecases/auth_use_cases.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_bookmark_button.dart';
import 'package:dramabyte_app/features/library/data/models/library_item_model.dart';
import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';
import 'package:dramabyte_app/features/library/domain/repositories/library_repository.dart';
import 'package:dramabyte_app/features/library/domain/usecases/library_use_cases.dart';
import 'package:dramabyte_app/features/library/presentation/cubit/library_cubit.dart';
import 'package:dramabyte_app/features/library/presentation/pages/library_page.dart';
import 'package:dramabyte_app/features/library/presentation/widgets/library_bookmark_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryItem item(int i) =>
    LibraryItem(seriesId: 's$i', title: 'Series $i', episodeCount: 5);

class _FakeAuth implements AuthRepository {
  @override
  Future<AuthUser?> cachedUser() async => const AuthUser('u1');

  @override
  Future<AuthUser?> restoreSession() async => const AuthUser('u1');

  @override
  Future<AuthUser?> signInWithGoogle(String? referralCode) async => null;

  @override
  Future<void> signOut() async {}
}

class FakeLibraryHandle implements LibraryRepository {
  var server = <LibraryItem>[item(1), item(2)];
  Completer<void>? gate;
  Failure? failure;
  final calls = <String>[];

  @override
  Future<List<LibraryItem>?> cached(String userId) async => null;

  @override
  Future<List<LibraryItem>> fetch(String userId) async => List.of(server);

  @override
  Stream<void> changes(String userId) => const Stream.empty();

  @override
  Future<void> add(String seriesId) async {
    calls.add('add:$seriesId');
    await gate?.future;
    if (failure != null) throw failure!;
    server = [item(int.parse(seriesId.substring(1))), ...server];
  }

  @override
  Future<void> remove(String seriesId) async {
    calls.add('remove:$seriesId');
    await gate?.future;
    if (failure != null) throw failure!;
    server = server.where((e) => e.seriesId != seriesId).toList();
  }
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));

LibraryCubit buildCubit(FakeLibraryHandle repository) {
  final auth = _FakeAuth();
  final bloc = AuthenticationBloc(
    RestoreSession(auth),
    SignInWithGoogle(auth),
    SignOut(auth),
    GetCachedUser(auth),
    const Stream.empty(),
  )..add(const AuthenticationStarted());
  return LibraryCubit(
    bloc,
    GetCachedLibrary(repository),
    GetLibrary(repository),
    WatchLibraryChanges(repository),
    AddToLibrary(repository),
    RemoveFromLibrary(repository),
  );
}

List<String> ids(LibraryCubit cubit) =>
    cubit.items!.map((e) => e.seriesId).toList();

void main() {
  late FakeLibraryHandle repository;
  late LibraryCubit cubit;

  setUp(() async {
    repository = FakeLibraryHandle();
    cubit = buildCubit(repository);
    await settle();
  });

  group('library cubit', () {
    test('loads the saved series', () {
      expect(ids(cubit), ['s1', 's2']);
      expect(cubit.isSaved('s1'), isTrue);
      expect(cubit.isSaved('s9'), isFalse);
    });

    test('saving is optimistic: shown before the server answers', () async {
      repository.gate = Completer();
      final result = cubit.toggle(item(9));
      expect(ids(cubit), ['s9', 's1', 's2']);
      expect(cubit.isSaved('s9'), isTrue);
      repository.gate!.complete();
      expect(await result, isNull);
      await settle();
      expect(ids(cubit), ['s9', 's1', 's2']);
      expect(repository.calls, ['add:s9']);
    });

    test('removing is optimistic too', () async {
      repository.gate = Completer();
      final result = cubit.toggle(item(1));
      expect(ids(cubit), ['s2']);
      repository.gate!.complete();
      expect(await result, isNull);
      expect(repository.calls, ['remove:s1']);
    });

    test('a rejected save rolls back and reports why', () async {
      repository.failure = const ValidationFailure('Your library is full');
      final message = await cubit.toggle(item(9));
      expect(message, 'Your library is full');
      expect(ids(cubit), ['s1', 's2']);
    });

    test('a rejected removal is restored to its original position', () async {
      repository.failure = const NetworkFailure('offline');
      expect(await cubit.toggle(item(1)), 'offline');
      expect(ids(cubit), ['s1', 's2']);
    });

    test('undoing a removal puts it back at the top', () async {
      await cubit.toggle(item(1));
      await cubit.toggle(item(1));
      await settle();
      expect(ids(cubit).first, 's1');
      expect(repository.calls, ['remove:s1', 'add:s1']);
    });

    test(
      'toggling before the library has loaded is refused politely',
      () async {
        final fresh = buildCubit(FakeLibraryHandle());
        final message = await fresh.toggle(item(9));
        expect(message, contains('still loading'));
      },
    );
  });

  test('entity subtitle and model parsing', () {
    expect(item(1).subtitle, '5 episodes');
    const free = LibraryItem(
      seriesId: 'a',
      title: 'A',
      genre: 'Romance',
      episodeCount: 45,
      freeEpisodeCount: 10,
    );
    expect(free.subtitle, 'Romance · 10 eps free · All 45');
    expect(LibraryItemModel(const {'title': 'x'}).toEntity(), isNull);
    final parsed = LibraryItemModel(const {
      'series_id': 's1',
      'episode_count': 'oops',
      'saved_at': 'not-a-date',
    }).toEntity()!;
    expect(parsed.episodeCount, 0);
    expect(parsed.savedAt, isNull);
  });

  Widget host(Widget child) => ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, _) => MaterialApp(
      home: BlocProvider.value(value: cubit, child: child),
    ),
  );

  testWidgets('library page lists saved series and shows the empty state', (
    tester,
  ) async {
    await tester.pumpWidget(host(LibraryPage(onExplore: () {})));
    await tester.pump();
    expect(find.text('Series 1'), findsOneWidget);
    expect(find.text('Series 2'), findsOneWidget);
    repository.server = [];
    await tester.runAsync(cubit.refresh);
    await tester.pump();
    expect(cubit.items, isEmpty);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Explore series'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bookmark button flips instantly and confirms', (tester) async {
    repository.gate = Completer();
    await tester.pumpWidget(
      host(
        Scaffold(
          body: Center(child: LibraryBookmarkButton(item: item(9))),
        ),
      ),
    );
    expect(cubit.isSaved('s9'), isFalse);
    await tester.tap(find.byType(LibraryBookmarkButton));
    await tester.pump();
    expect(cubit.isSaved('s9'), isTrue);
    expect(find.text('Saved to Library'), findsOneWidget);
    repository.gate!.complete();
    await tester.pumpAndSettle();
    expect(cubit.isSaved('s9'), isTrue);
    await tester.tap(find.byType(LibraryBookmarkButton));
    await tester.pump();
    expect(cubit.isSaved('s9'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reel rail bookmark saves the series optimistically', (
    tester,
  ) async {
    repository.gate = Completer();
    const reel = Reel(
      episodeId: 'e9',
      seriesId: 's9',
      title: 'Series 9',
      genre: 'Drama',
      publishedCount: 12,
    );
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: Center(child: ReelBookmarkButton(reel: reel)),
        ),
      ),
    );
    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byType(ReelBookmarkButton));
    await tester.pump();
    expect(find.text('Saved'), findsOneWidget);
    expect(cubit.items!.first.episodeCount, 12);
    expect(repository.calls, ['add:s9']);
    repository.gate!.complete();
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ReelBookmarkButton));
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('state type sanity', () {
    expect(cubit.state, isA<ResourceLoaded<List<LibraryItem>>>());
  });
}
