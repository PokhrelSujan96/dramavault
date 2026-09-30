import 'dart:async';

import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/format/time_ago.dart';
import 'package:dramabyte_app/features/comments/data/models/comment_models.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:dramabyte_app/features/comments/domain/repositories/comment_repository.dart';
import 'package:dramabyte_app/features/comments/domain/usecases/comment_use_cases.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comment_tree.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_args.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/engagement/domain/repositories/engagement_repository.dart';
import 'package:dramabyte_app/features/engagement/domain/usecases/engagement_use_cases.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

Comment comment(
  String id, {
  String? parent,
  int likes = 0,
  int replies = 0,
  bool liked = false,
  bool mine = false,
}) => Comment(
  id: id,
  episodeId: 'ep',
  body: 'Body $id',
  authorId: mine ? 'me' : 'other',
  authorName: mine ? 'Me' : 'Sam',
  parentId: parent,
  likeCount: likes,
  replyCount: replies,
  liked: liked,
  isMine: mine,
  createdAt: DateTime(2026, 1, 1),
);

class FakeCommentRepository implements CommentRepository {
  final pages = <String, CommentPage>{};
  final replyPages = <String, CommentPage>{};
  final calls = <String>[];
  final posts = <PostCommentParams>[];
  Failure? failure;
  Failure? postFailure;
  Completer<void>? gate;

  @override
  Future<CommentPage> list(
    String episodeId, {
    required CommentSort sort,
    String? cursor,
  }) async {
    calls.add('list:${sort.name}:${cursor ?? '-'}');
    if (failure != null) throw failure!;
    return pages['${sort.name}:${cursor ?? '-'}'] ??
        pages[cursor ?? '-'] ??
        const CommentPage([], null);
  }

  @override
  Future<CommentPage> replies(String commentId, {String? cursor}) async {
    calls.add('replies:$commentId:${cursor ?? '-'}');
    return replyPages['$commentId:${cursor ?? '-'}'] ??
        const CommentPage([], null);
  }

  @override
  Future<Comment> post({
    required String episodeId,
    required String body,
    required String key,
    String? parentId,
  }) async {
    posts.add(
      PostCommentParams(
        episodeId: episodeId,
        body: body,
        key: key,
        parentId: parentId,
      ),
    );
    await gate?.future;
    if (postFailure != null) throw postFailure!;
    return Comment(
      id: 'real-${posts.length}',
      episodeId: episodeId,
      body: body,
      authorId: 'me',
      parentId: parentId,
      isMine: true,
      authorName: 'Me',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> setLike(String commentId, {required bool liked}) async {
    calls.add('like:$commentId:$liked');
    if (failure != null) throw failure!;
  }

  @override
  Future<void> delete(String commentId) async {
    calls.add('delete:$commentId');
    if (failure != null) throw failure!;
  }

  @override
  Future<void> report(String commentId, String reason) async {
    calls.add('report:$commentId:$reason');
    if (failure != null) throw failure!;
  }
}

CommentsCubit buildCubit(FakeCommentRepository repository, List<int> counts) =>
    CommentsCubit(
      const CommentsArgs(episodeId: 'ep', authorId: 'me', authorName: 'Me'),
      ListComments(repository),
      ListReplies(repository),
      PostComment(repository),
      SetCommentLike(repository),
      DeleteComment(repository),
      ReportComment(repository),
      onCountChanged: counts.add,
      likeDelay: const Duration(milliseconds: 20),
    );

Future<void> settle([int ms = 60]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

class _NoopEngagement implements EngagementRepository {
  @override
  Future<void> setLike(String episodeId, {required bool liked}) async {}

  @override
  void recordView(String episodeId) {}

  @override
  Future<void> flushViews() async {}
}

void main() {
  group('formatting and parsing', () {
    test('time ago', () {
      final now = DateTime(2026, 6, 15, 12);
      String ago(Duration d) => timeAgo(now.subtract(d), now: now);
      expect(ago(const Duration(seconds: 10)), 'now');
      expect(ago(const Duration(minutes: 5)), '5m');
      expect(ago(const Duration(hours: 3)), '3h');
      expect(ago(const Duration(days: 2)), '2d');
      expect(ago(const Duration(days: 15)), '2w');
      expect(ago(const Duration(days: 40)), 'May 6');
      expect(timeAgo(DateTime(2024, 3, 2), now: now), 'Mar 2, 2024');
      expect(timeAgo(null), '');
    });

    test('model tolerates missing fields and bad types', () {
      expect(CommentModel(const {'id': 'x'}).toEntity(), isNull);
      final parsed = CommentModel(const {
        'id': 'c1',
        'author_id': 'a',
        'body': 'hi',
        'like_count': 'oops',
        'created_at': 'nope',
        'liked': true,
      }).toEntity()!;
      expect(
        (parsed.likeCount, parsed.createdAt, parsed.liked),
        (0, null, true),
      );
      final page = CommentPageModel.fromJson({
        'items': [
          {'id': 'c1', 'author_id': 'a', 'body': 'x'},
          'garbage',
        ],
        'next_cursor': '',
      }).toEntity();
      expect(page.items.length, 1);
      expect(page.nextCursor, isNull);
    });
  });

  group('comment tree', () {
    final base = CommentsState(
      status: CommentsStatus.ready,
      items: [comment('a', replies: 1), comment('b')],
      replies: {
        'a': RepliesState(items: [comment('r1', parent: 'a')], loaded: true),
      },
    );

    test('a top-level comment is added first; a reply joins its thread', () {
      final top = base.addLocal(comment('new'));
      expect(top.items.first.id, 'new');
      final reply = base.addLocal(comment('r2', parent: 'a'));
      expect(reply.repliesOf('a').items.map((c) => c.id), ['r1', 'r2']);
      expect(reply.repliesOf('a').expanded, isTrue);
      expect(reply.items.first.replyCount, 2);
    });

    test('replace, mutate and remove work for comments and replies', () {
      final replaced = base
          .addLocal(comment('temp', parent: 'a'))
          .replaceLocal('temp', comment('real', parent: 'a'));
      expect(replaced.repliesOf('a').items.last.id, 'real');
      final liked = base.mutate('r1', (c) => c.copyWith(liked: true));
      expect(liked.find('r1')!.liked, isTrue);
      expect(base.find('missing'), isNull);
      final gone = base.removeLocal(comment('r1', parent: 'a'));
      expect(gone.repliesOf('a').items, isEmpty);
      expect(gone.items.first.replyCount, 0);
      final topGone = base.removeLocal(comment('a'));
      expect(topGone.items.map((c) => c.id), ['b']);
      expect(topGone.replies.containsKey('a'), isFalse);
    });
  });

  group('comments cubit', () {
    late FakeCommentRepository repository;
    late List<int> counts;
    late CommentsCubit cubit;

    setUp(() {
      repository = FakeCommentRepository()
        ..pages['-'] = CommentPage([
          comment('a', replies: 3),
          comment('b'),
        ], 'c1')
        ..pages['c1'] = CommentPage([comment('b'), comment('c')], null);
      counts = [];
      cubit = buildCubit(repository, counts);
    });

    test('loads the first page and paginates without duplicates', () async {
      await cubit.load();
      expect(cubit.state.status, CommentsStatus.ready);
      await cubit.loadMore();
      expect(cubit.state.items.map((c) => c.id), ['a', 'b', 'c']);
      expect(cubit.state.nextCursor, isNull);
      await cubit.loadMore();
      expect(repository.calls.where((c) => c.startsWith('list')).length, 2);
    });

    test('a failed load shows an error and retry recovers', () async {
      repository.failure = const NetworkFailure('offline');
      await cubit.load();
      expect(cubit.state.status, CommentsStatus.failure);
      expect(cubit.state.error, 'offline');
      repository.failure = null;
      await cubit.load();
      expect(cubit.state.status, CommentsStatus.ready);
    });

    test('changing the sort reloads with the new order', () async {
      await cubit.load();
      await cubit.setSort(CommentSort.newest);
      expect(repository.calls.last, 'list:newest:-');
      expect(cubit.state.sort, CommentSort.newest);
    });

    test('posting is optimistic: visible instantly, then confirmed', () async {
      await cubit.load();
      repository.gate = Completer();
      final future = cubit.post('  hello  ');
      expect(cubit.state.items.first.pending, isTrue);
      expect(cubit.state.items.first.body, 'hello');
      expect(counts, [1]);
      repository.gate!.complete();
      expect(await future, isNull);
      expect(cubit.state.items.first.pending, isFalse);
      expect(cubit.state.items.first.id, startsWith('real-'));
    });

    test('a failed post is removed, counted back, and reports why', () async {
      await cubit.load();
      repository.postFailure = const ValidationFailure('Too fast');
      expect(await cubit.post('hello'), 'Too fast');
      expect(cubit.state.items.map((c) => c.id), ['a', 'b']);
      expect(counts, [1, -1]);
    });

    test('retrying the same text reuses the idempotency key', () async {
      await cubit.load();
      repository.postFailure = const NetworkFailure('offline');
      await cubit.post('hello');
      await cubit.post('hello');
      repository.postFailure = null;
      await cubit.post('hello');
      await cubit.post('hello');
      final keys = repository.posts.map((p) => p.key).toList();
      expect(keys[0], keys[1]);
      expect(keys[1], keys[2]);
      expect(keys[3], isNot(keys[2]));
    });

    test('replying to a reply attaches to the thread and expands it', () async {
      await cubit.load();
      final reply = comment('r1', parent: 'a');
      cubit.startReply(reply);
      expect(cubit.state.replyTo, reply);
      await cubit.post('answer');
      expect(repository.posts.single.parentId, 'r1');
      expect(cubit.state.repliesOf('a').items.single.id, startsWith('real-'));
      expect(cubit.state.repliesOf('a').expanded, isTrue);
      expect(cubit.state.items.first.replyCount, 4);
      expect(cubit.state.replyTo, isNull);
    });

    test('cancelling a reply clears the target', () async {
      await cubit.load();
      cubit.startReply(comment('a'));
      cubit.cancelReply();
      expect(cubit.state.replyTo, isNull);
    });

    test('expanding loads replies once; own new reply is kept', () async {
      repository.replyPages['a:-'] = CommentPage([
        comment('r1', parent: 'a'),
        comment('r2', parent: 'a'),
      ], 'rc');
      repository.replyPages['a:rc'] = CommentPage([
        comment('r3', parent: 'a'),
      ], null);
      await cubit.load();
      final top = cubit.state.items.first;
      await cubit.toggleReplies(top);
      expect(cubit.state.repliesOf('a').items.map((c) => c.id), ['r1', 'r2']);
      expect(cubit.state.repliesOf('a').loaded, isTrue);
      await cubit.loadReplies('a');
      expect(cubit.state.repliesOf('a').items.map((c) => c.id), [
        'r1',
        'r2',
        'r3',
      ]);
      await cubit.toggleReplies(top);
      expect(cubit.state.repliesOf('a').expanded, isFalse);
      await cubit.toggleReplies(top);
      expect(repository.calls.where((c) => c.startsWith('replies')).length, 2);
    });

    test('liking is optimistic and syncs once after a pause', () async {
      await cubit.load();
      final target = cubit.state.items.first;
      cubit.toggleLike(target);
      expect(cubit.state.items.first.liked, isTrue);
      expect(cubit.state.items.first.likeCount, 1);
      await settle();
      expect(repository.calls.where((c) => c.startsWith('like')), [
        'like:a:true',
      ]);
    });

    test('like then unlike quickly sends nothing', () async {
      await cubit.load();
      final target = cubit.state.items.first;
      cubit
        ..toggleLike(target)
        ..toggleLike(cubit.state.items.first);
      await settle();
      expect(repository.calls.where((c) => c.startsWith('like')), isEmpty);
      expect(cubit.state.items.first.likeCount, 0);
    });

    test('a failed like rolls back with a notice', () async {
      await cubit.load();
      repository.failure = const NetworkFailure('offline');
      cubit.toggleLike(cubit.state.items.first);
      await settle();
      expect(cubit.state.items.first.liked, isFalse);
      expect(cubit.state.items.first.likeCount, 0);
      expect(cubit.state.notice, 'offline');
    });

    test('deleting removes the whole thread and adjusts the count', () async {
      repository.pages['-'] = CommentPage([
        comment('a', replies: 2, mine: true),
      ], null);
      await cubit.load();
      await cubit.delete(cubit.state.items.first);
      expect(cubit.state.items, isEmpty);
      expect(counts, [-3]);
      expect(repository.calls, contains('delete:a'));
    });

    test('a failed delete restores the comment', () async {
      repository.pages['-'] = CommentPage([comment('a', mine: true)], null);
      await cubit.load();
      repository.failure = const NetworkFailure('offline');
      await cubit.delete(cubit.state.items.first);
      expect(cubit.state.items.single.id, 'a');
      expect(counts, [-1, 1]);
      expect(cubit.state.notice, 'offline');
    });

    test(
      "others' comments cannot be deleted; reports show a thank-you",
      () async {
        await cubit.load();
        await cubit.delete(cubit.state.items.first);
        expect(repository.calls.where((c) => c.startsWith('delete')), isEmpty);
        await cubit.report(cubit.state.items.first, 'Spam');
        expect(repository.calls.last, 'report:a:Spam');
        expect(cubit.state.notice, contains('Thanks'));
      },
    );
  });

  group('comments sheet', () {
    late FakeCommentRepository repository;
    late EngagementCubit engagement;

    setUp(() async {
      repository = FakeCommentRepository()
        ..pages['-'] = CommentPage([
          comment('a', replies: 2, likes: 1200),
          comment('b', mine: true),
        ], null)
        ..replyPages['a:-'] = CommentPage([comment('r1', parent: 'a')], null);
      await getIt.reset();
      getIt.registerFactoryParam<CommentsCubit, CommentsArgs, void>(
        (args, _) => buildCubit(repository, []),
      );
      final engagementRepo = _NoopEngagement();
      engagement = EngagementCubit(
        SetLike(engagementRepo),
        RecordView(engagementRepo),
        FlushViews(engagementRepo),
      );
    });

    tearDown(() async => getIt.reset());

    Future<void> pumpSheet(WidgetTester tester, {double width = 390}) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: BlocProvider.value(
              value: engagement,
              child: const Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: CommentsSheet(
                    args: CommentsArgs(
                      episodeId: 'ep',
                      authorId: 'me',
                      authorName: 'Me',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
    }

    testWidgets('renders comments with counts, likes and replies', (
      tester,
    ) async {
      await pumpSheet(tester);
      expect(find.text('Body a'), findsOneWidget);
      expect(find.text('Body b'), findsOneWidget);
      expect(find.text('1.2K'), findsOneWidget);
      expect(find.text('View 2 replies'), findsOneWidget);
      await tester.tap(find.text('View 2 replies'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Body r1'), findsOneWidget);
      expect(find.text('Hide'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('posting shows the comment instantly and clears the box', (
      tester,
    ) async {
      await pumpSheet(tester);
      repository.gate = Completer();
      await tester.enterText(find.byType(TextField), 'Love this show');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(find.text('Love this show'), findsOneWidget);
      expect(find.text('Posting…'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      repository.gate!.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Posting…'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed post restores the text and explains why', (
      tester,
    ) async {
      await pumpSheet(tester);
      repository.postFailure = const ValidationFailure(
        'You are commenting too fast',
      );
      await tester.enterText(find.byType(TextField), 'Hello there');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Hello there',
      );
      expect(find.text('You are commenting too fast'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Hello there'),
        ),
        findsNothing,
      );
    });

    testWidgets('tapping Reply shows who you are replying to', (tester) async {
      await pumpSheet(tester);
      await tester.tap(find.text('Reply').first);
      await tester.pumpAndSettle();
      expect(find.text('Replying to Sam'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.text('Replying to Sam'), findsNothing);
    });

    testWidgets('the header shows the live comment count', (tester) async {
      engagement.seed([
        const Reel(episodeId: 'ep', seriesId: 's', title: 'T', comments: 1500),
      ]);
      await pumpSheet(tester);
      expect(find.text('1.5K comments'), findsOneWidget);
    });

    testWidgets('fits very narrow phones', (tester) async {
      await pumpSheet(tester, width: 320);
      expect(tester.takeException(), isNull);
    });
  });
}
