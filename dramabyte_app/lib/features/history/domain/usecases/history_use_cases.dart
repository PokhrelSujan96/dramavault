import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_page.dart';
import 'package:dramabyte_app/features/history/domain/repositories/history_repository.dart';

final class GetCachedHistory implements UseCase<List<HistoryItem>?, String> {
  GetCachedHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<List<HistoryItem>?> call(String params) => _repository.cached(params);
}

final class GetRecentHistory implements UseCase<List<HistoryItem>, String> {
  GetRecentHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<List<HistoryItem>> call(String params) => _repository.recent(params);
}

final class WatchHistoryChanges {
  WatchHistoryChanges(this._repository);

  final HistoryRepository _repository;

  Stream<void> call(String userId) => _repository.changes(userId);
}

final class GetHistoryPage implements UseCase<HistoryPage, String?> {
  GetHistoryPage(this._repository);

  final HistoryRepository _repository;

  @override
  Future<HistoryPage> call(String? params) => _repository.page(params);
}

final class RecordWatchParams {
  const RecordWatchParams(this.episodeId, this.seconds);

  final String episodeId;
  final int seconds;
}

final class RecordWatch implements UseCase<void, RecordWatchParams> {
  RecordWatch(this._repository);

  final HistoryRepository _repository;

  @override
  Future<void> call(RecordWatchParams params) =>
      _repository.record(params.episodeId, params.seconds);
}

final class RemoveHistory implements UseCase<void, String?> {
  RemoveHistory(this._repository);

  final HistoryRepository _repository;

  @override
  Future<void> call(String? params) => _repository.remove(params);
}
