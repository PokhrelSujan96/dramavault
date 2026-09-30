import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/discover_repository.dart';
import 'package:dramabyte_app/features/discover/domain/usecases/discover_use_cases.dart';
import 'package:dramabyte_app/features/discover/presentation/cubit/discover_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Reel reel(int i) => Reel(episodeId: 'e$i', seriesId: 's$i', title: 'T$i');

class _FakeRepository implements DiscoverRepository {
  final pages = <String?, ReelPage>{};
  ReelPage? cachedPage;
  List<Reel> saved = [];
  bool offline = false;
  final requested = <String?>[];

  @override
  Future<ReelPage?> cachedFirstPage() async => cachedPage;

  @override
  Future<ReelPage> fetchPage({String? cursor}) async {
    requested.add(cursor);
    if (offline) throw const NetworkFailure('offline');
    return pages[cursor]!;
  }

  @override
  Future<List<Reel>> offlineReels() async => saved;
}

void main() {
  late _FakeRepository repository;
  late DiscoverCubit cubit;

  setUp(() {
    repository = _FakeRepository()
      ..pages[null] = ReelPage([reel(1), reel(2)], 'c1')
      ..pages['c1'] = ReelPage([reel(2), reel(3)], null);
    cubit = DiscoverCubit(
      GetCachedReelPage(repository),
      GetReelPage(repository),
      GetOfflineReels(repository),
    );
  });

  test('loads the first page', () async {
    await cubit.load();
    expect(cubit.state.status, DiscoverStatus.ready);
    expect(cubit.state.reels.length, 2);
    expect(cubit.state.hasMore, isTrue);
  });

  test('paginates without duplicates and stops at the end', () async {
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.reels.map((r) => r.episodeId), ['e1', 'e2', 'e3']);
    expect(cubit.state.hasMore, isFalse);
    await cubit.loadMore();
    expect(repository.requested, [null, 'c1']);
  });

  test('a failed page keeps the list and can be retried', () async {
    await cubit.load();
    repository.offline = true;
    await cubit.loadMore();
    expect(cubit.state.reels.length, 2);
    expect(cubit.state.loadingMore, isFalse);
    expect(cubit.state.hasMore, isTrue);
    repository.offline = false;
    await cubit.loadMore();
    expect(cubit.state.reels.length, 3);
  });

  test('falls back to saved episodes when offline', () async {
    repository
      ..offline = true
      ..saved = [reel(9)];
    await cubit.load();
    expect(cubit.state.status, DiscoverStatus.ready);
    expect(cubit.state.offline, isTrue);
    await cubit.loadMore();
    expect(repository.requested, [null]);
  });

  test('shows a failure when offline with nothing saved', () async {
    repository.offline = true;
    await cubit.load();
    expect(cubit.state.status, DiscoverStatus.failure);
    expect(cubit.state.error, 'offline');
  });

  test(
    'shows the cached first page immediately, then merges fresh data',
    () async {
      repository.cachedPage = ReelPage([reel(1), reel(2)], 'c1');
      repository.pages[null] = ReelPage([
        const Reel(episodeId: 'e2', seriesId: 's2', title: 'Fresh2'),
        reel(9),
      ], 'c1');
      final states = <DiscoverState>[];
      cubit.stream.listen(states.add);
      await cubit.load();
      expect(states.first.status, DiscoverStatus.ready);
      expect(states.first.reels.map((r) => r.episodeId), ['e1', 'e2']);
      expect(states.any((s) => s.status == DiscoverStatus.loading), isFalse);
      expect(cubit.state.reels.map((r) => r.episodeId), ['e1', 'e2', 'e9']);
      expect(cubit.state.reels[1].title, 'Fresh2');
    },
  );

  test('a failed refresh keeps the cached feed and marks it offline', () async {
    repository
      ..cachedPage = ReelPage([reel(1)], null)
      ..offline = true;
    await cubit.load();
    expect(cubit.state.status, DiscoverStatus.ready);
    expect(cubit.state.reels.length, 1);
    expect(cubit.state.offline, isTrue);
  });

  test('refresh merges without dropping scrolled pages', () async {
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.reels.length, 3);
    repository.pages[null] = ReelPage([reel(1), reel(2), reel(7)], 'c1');
    await cubit.refresh();
    expect(cubit.state.reels.map((r) => r.episodeId), ['e1', 'e2', 'e3', 'e7']);
    expect(cubit.state.hasMore, isFalse);
  });

  test('model skips malformed items and tolerates missing fields', () {
    final page = ReelPageModel.fromJson({
      'items': [
        {'episode_id': 'a', 'title': 'A', 'likes': 'oops'},
        {'title': 'no id'},
        'garbage',
      ],
      'next_cursor': '',
    }).toEntity();
    expect(page.items.length, 1);
    expect(page.items.first.likes, 0);
    expect(page.items.first.episodeNumber, 1);
    expect(page.nextCursor, isNull);
  });
}
