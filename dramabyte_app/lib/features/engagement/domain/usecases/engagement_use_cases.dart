import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/engagement/domain/repositories/engagement_repository.dart';

final class SetLikeParams {
  const SetLikeParams(this.episodeId, {required this.liked});

  final String episodeId;
  final bool liked;
}

final class SetLike implements UseCase<void, SetLikeParams> {
  SetLike(this._repository);

  final EngagementRepository _repository;

  @override
  Future<void> call(SetLikeParams params) =>
      _repository.setLike(params.episodeId, liked: params.liked);
}

final class RecordView {
  RecordView(this._repository);

  final EngagementRepository _repository;

  void call(String episodeId) => _repository.recordView(episodeId);
}

final class FlushViews implements UseCase<void, NoParams> {
  FlushViews(this._repository);

  final EngagementRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.flushViews();
}
