import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/history/data/models/history_models.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_page.dart';
import 'package:dramabyte_app/features/history/domain/repositories/history_repository.dart';
import 'package:dramabyte_app/features/history/domain/usecases/history_use_cases.dart';
import 'package:dramabyte_app/features/history/presentation/cubit/history_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

HistoryItem item(int i, {int position = 10, int duration = 100}) => HistoryItem(
  episodeId: 'e$i',
  title: 'T$i',
  positionSeconds: position,
  durationSeconds: duration,
);

class _FakeRepository implements HistoryRepository {
  final pages = <String?, HistoryPage>{};
  final removed = <String?>[];
  bool failRemove = false;

  @override
  Future<HistoryPage> page(String? cursor) async => pages[cursor]!;

  @override
  Future<void> remove(String? episodeId) async {
    if (failRemove) throw const NetworkFailure('offline');
    removed.add(episodeId);
  }

  @override
  Future<List<HistoryItem>?> cached(String userId) async => null;

  @override
  Future<List<HistoryItem>> recent(String userId) async => const [];

  @override
  Stream<void> changes(String userId) => const Stream.empty();

  @override
  Future<void> record(String episodeId, int seconds) async {}
}

void main() {
  late _FakeRepository repository;
  late HistoryListCubit cubit;

  setUp(() {
    repository = _FakeRepository()
      ..pages[null] = HistoryPage([item(1), item(2)], 'c1')
      ..pages['c1'] = HistoryPage([item(2), item(3)], null);
    cubit = HistoryListCubit(
      GetHistoryPage(repository),
      RemoveHistory(repository),
    );
  });

  test('progress is clamped and completion is detected', () {
    expect(item(1, position: 50).progress, 0.5);
    expect(item(1, position: 500).progress, 1);
    expect(item(1, duration: 0).progress, 0);
    expect(item(1, position: 96).isCompleted, isTrue);
    expect(item(1, position: 40).isCompleted, isFalse);
  });

  test('paginates without duplicates', () async {
    await cubit.load();
    await cubit.loadMore();
    expect(cubit.state.items.map((i) => i.episodeId), ['e1', 'e2', 'e3']);
    expect(cubit.state.nextCursor, isNull);
  });

  test('remove is optimistic and reaches the repository', () async {
    await cubit.load();
    final done = cubit.remove('e1');
    expect(cubit.state.items.map((i) => i.episodeId), ['e2']);
    await done;
    expect(repository.removed, ['e1']);
  });

  test('a failed remove rolls back and tells the user', () async {
    await cubit.load();
    repository.failRemove = true;
    await cubit.remove('e1');
    expect(cubit.state.items.length, 2);
    expect(cubit.state.notice, 'offline');
  });

  test('clear empties the list', () async {
    await cubit.load();
    await cubit.remove(null);
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.nextCursor, isNull);
    expect(repository.removed, [null]);
  });

  test('model skips malformed rows and tolerates bad types', () {
    final page = HistoryPageModel.fromJson({
      'items': [
        {'episode_id': 'a', 'title': 'A', 'position_seconds': 'x'},
        {'title': 'no id'},
      ],
    }).toEntity();
    expect(page.items.length, 1);
    expect(page.items.first.positionSeconds, 0);
    expect(page.nextCursor, isNull);
  });
}
