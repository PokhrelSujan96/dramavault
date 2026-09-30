import 'dart:async';

import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/core/format/uuid.dart';
import 'package:dramabyte_app/core/gestures/double_tap_detector.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_like_button.dart';
import 'package:dramabyte_app/features/engagement/data/datasources/view_batcher.dart';
import 'package:dramabyte_app/features/engagement/domain/repositories/engagement_repository.dart';
import 'package:dramabyte_app/features/engagement/domain/usecases/engagement_use_cases.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException httpError(int status) => DioException(
  requestOptions: RequestOptions(path: '/views/batch'),
  response: Response(
    requestOptions: RequestOptions(path: '/views/batch'),
    statusCode: status,
  ),
);

Future<void> wait([int ms = 80]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

class FakeEngagementRepository implements EngagementRepository {
  final likes = <bool>[];
  final views = <String>[];
  int flushes = 0;
  Failure? failure;
  Completer<void>? gate;

  @override
  Future<void> setLike(String episodeId, {required bool liked}) async {
    likes.add(liked);
    await gate?.future;
    if (failure != null) throw failure!;
  }

  @override
  void recordView(String episodeId) => views.add(episodeId);

  @override
  Future<void> flushViews() async => flushes++;
}

EngagementCubit buildCubit(FakeEngagementRepository repository) =>
    EngagementCubit(
      SetLike(repository),
      RecordView(repository),
      FlushViews(repository),
      likeDelay: const Duration(milliseconds: 20),
    );

Reel reel({
  int likes = 10,
  int views = 100,
  bool liked = false,
  String id = 'e1',
}) => Reel(
  episodeId: id,
  seriesId: 's',
  title: 'T',
  likes: likes,
  views: views,
  liked: liked,
);

void main() {
  group('formatting and gestures', () {
    test('compact counts', () {
      expect(compactCount(0), '0');
      expect(compactCount(999), '999');
      expect(compactCount(1000), '1K');
      expect(compactCount(1234), '1.23K');
      expect(compactCount(34680), '34.68K');
      expect(compactCount(1250000), '1.25M');
      expect(compactCount(3000000000), '3B');
    });

    test('uuid v4 shape is valid and unique', () {
      final pattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      final ids = {for (var i = 0; i < 50; i++) generateUuidV4()};
      expect(ids.length, 50);
      expect(ids.every(pattern.hasMatch), isTrue);
    });

    test('double tap detector uses a time window', () {
      var now = DateTime(2026);
      final detector = DoubleTapDetector(clock: () => now);
      expect(detector.register(), isFalse);
      now = now.add(const Duration(milliseconds: 100));
      expect(detector.register(), isTrue);
      now = now.add(const Duration(milliseconds: 100));
      expect(detector.register(), isFalse);
      now = now.add(const Duration(milliseconds: 500));
      expect(detector.register(), isFalse);
    });

    test('reel model reads views and liked', () {
      final parsed = ReelModel(const {
        'episode_id': 'e',
        'views': 1500,
        'liked': true,
      }).toEntity()!;
      expect((parsed.views, parsed.liked), (1500, true));
      expect(parsed.viewsLabel, '1.5K');
      final bad = ReelModel(const {
        'episode_id': 'e',
        'views': 'x',
        'liked': 'yes',
      }).toEntity()!;
      expect((bad.views, bad.liked), (0, false));
    });
  });

  group('view batcher', () {
    late List<(String, Map<String, int>)> sent;
    late List<Object> failures;
    late SharedPreferences prefs;

    ViewBatcher make({int threshold = 100, int maxItems = 50}) => ViewBatcher(
      (id, items) async {
        sent.add((id, Map.of(items)));
        if (failures.isNotEmpty) throw failures.removeAt(0);
      },
      prefs,
      interval: const Duration(milliseconds: 20),
      maxBackoff: const Duration(milliseconds: 200),
      threshold: threshold,
      maxItems: maxItems,
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      sent = [];
      failures = [];
    });

    test('aggregates every view into one request per interval', () async {
      final batcher = make()
        ..record('a')
        ..record('a')
        ..record('a')
        ..record('b');
      expect(sent, isEmpty);
      await wait();
      expect(sent.length, 1);
      expect(sent.single.$2, {'a': 3, 'b': 1});
      expect(batcher.pendingTotal, 0);
    });

    test(
      'every view counts: repeats of the same episode are not deduplicated',
      () async {
        final batcher = make();
        for (var i = 0; i < 40; i++) {
          batcher.record('same');
        }
        await wait();
        expect(sent.single.$2['same'], 40);
      },
    );

    test('flushes immediately once the threshold is reached', () async {
      final batcher = make(threshold: 3)
        ..record('a')
        ..record('a')
        ..record('b');
      await wait(5);
      expect(sent.length, 1);
      expect(batcher.pendingTotal, 0);
    });

    test(
      'a failed send is retried with the SAME batch id (no double count)',
      () async {
        failures = [httpError(500)];
        make().record('a');
        await wait(200);
        expect(sent.length, 2);
        expect(sent[0].$1, sent[1].$1);
        expect(sent[1].$2, {'a': 1});
      },
    );

    test('rate limiting and auth errors keep the batch for later', () async {
      failures = [httpError(429), httpError(401)];
      make().record('a');
      await wait(300);
      expect(sent.length, 3);
      expect(sent.map((s) => s.$1).toSet().length, 1);
    });

    test(
      'a permanent client error drops the batch instead of looping',
      () async {
        failures = [httpError(422)];
        final batcher = make()..record('a');
        await wait(150);
        expect(sent.length, 1);
        expect(batcher.pendingTotal, 0);
      },
    );

    test('views recorded while a send is failing are not lost', () async {
      failures = [httpError(500)];
      final batcher = make()..record('a');
      await wait(5);
      batcher.record('b');
      await wait(250);
      final delivered = <String, int>{};
      for (final entry in sent.skip(1)) {
        entry.$2.forEach((k, v) => delivered[k] = (delivered[k] ?? 0) + v);
      }
      expect(delivered, {'a': 1, 'b': 1});
    });

    test('large queues are split into requests of at most maxItems', () async {
      final batcher = make(maxItems: 2);
      for (final id in ['a', 'b', 'c', 'd', 'e']) {
        batcher.record(id);
      }
      await wait(100);
      expect(sent.map((s) => s.$2.length), [2, 2, 1]);
    });

    test(
      'unsent views survive an app restart with the same batch id',
      () async {
        failures = [httpError(500), httpError(500), httpError(500)];
        make()
          ..record('a')
          ..record('b');
        await wait(30);
        final firstId = sent.first.$1;
        sent.clear();
        failures = [];
        final restarted = make();
        expect(restarted.pendingTotal, 0);
        await wait(100);
        expect(sent.first.$1, firstId);
        expect(sent.first.$2, {'a': 1, 'b': 1});
      },
    );
  });

  group('engagement cubit', () {
    late FakeEngagementRepository repository;
    late EngagementCubit cubit;

    setUp(() {
      repository = FakeEngagementRepository();
      cubit = buildCubit(repository);
    });

    test('flushes any persisted views when it starts', () {
      expect(repository.flushes, 1);
    });

    test('liking is optimistic and sends a single request', () async {
      cubit.seed([reel(likes: 10)]);
      cubit.toggleLike('e1');
      expect(cubit.state.of('e1').liked, isTrue);
      expect(cubit.state.of('e1').likes, 11);
      expect(repository.likes, isEmpty);
      await wait();
      expect(repository.likes, [true]);
    });

    test('rapid like then unlike cancels out without any request', () async {
      cubit.seed([reel(likes: 10)]);
      cubit
        ..toggleLike('e1')
        ..toggleLike('e1');
      await wait();
      expect(repository.likes, isEmpty);
      expect(cubit.state.of('e1').likes, 10);
    });

    test('double tap only ever likes', () async {
      cubit.seed([reel(likes: 5, liked: true)]);
      cubit.like('e1');
      await wait();
      expect(repository.likes, isEmpty);
      expect(cubit.state.of('e1').likes, 5);
    });

    test('a failed like rolls back and tells the user', () async {
      cubit.seed([reel(likes: 10)]);
      repository.failure = const NetworkFailure('offline');
      cubit.toggleLike('e1');
      await wait();
      expect(cubit.state.of('e1').liked, isFalse);
      expect(cubit.state.of('e1').likes, 10);
      expect(cubit.state.notice, 'offline');
    });

    test(
      'toggling again while a request is in flight sends the final state',
      () async {
        cubit.seed([reel(likes: 10)]);
        repository.gate = Completer();
        cubit.toggleLike('e1');
        await wait(40);
        cubit.toggleLike('e1');
        repository.gate!.complete();
        await wait(120);
        expect(repository.likes, [true, false]);
        expect(cubit.state.of('e1').liked, isFalse);
      },
    );

    test('seeding never overwrites a like that is still being sent', () async {
      cubit.seed([reel(likes: 10)]);
      cubit.toggleLike('e1');
      cubit.seed([reel(likes: 10)]);
      expect(cubit.state.of('e1').liked, isTrue);
      await wait();
    });

    test('seeding refreshes counts and keeps the higher view number', () {
      cubit.seed([reel(views: 100, likes: 1)]);
      cubit.viewed('e1');
      expect(cubit.state.of('e1').views, 101);
      cubit.seed([reel(views: 100, likes: 2)]);
      expect(cubit.state.of('e1').views, 101);
      expect(cubit.state.of('e1').likes, 2);
      cubit.seed([reel(views: 500, likes: 2)]);
      expect(cubit.state.of('e1').views, 500);
    });

    test('every view bumps the count instantly and is queued', () {
      cubit.seed([reel(views: 10)]);
      cubit
        ..viewed('e1')
        ..viewed('e1')
        ..viewed('e1');
      expect(cubit.state.of('e1').views, 13);
      expect(repository.views, ['e1', 'e1', 'e1']);
    });
  });

  group('rail widgets', () {
    late FakeEngagementRepository repository;
    late EngagementCubit cubit;

    setUp(() {
      repository = FakeEngagementRepository();
      cubit = buildCubit(repository);
    });

    Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: Center(child: child),
          ),
        ),
      ),
    );

    testWidgets('like button shows the count, flips instantly and syncs once', (
      tester,
    ) async {
      final r = reel(likes: 99, liked: false);
      cubit.seed([r]);
      await tester.pumpWidget(host(ReelLikeButton(reel: r)));
      expect(find.text('99'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
      await tester.tap(find.byType(ReelLikeButton));
      await tester.pump();
      expect(find.text('100'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() => wait(60));
      expect(repository.likes, [true]);
      expect(tester.takeException(), isNull);
    });
  });
}
