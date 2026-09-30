import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_source.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/reel_media_repository.dart';

final class ResolveReelSource implements UseCase<ReelSource, Reel> {
  ResolveReelSource(this._repository);

  final ReelMediaRepository _repository;

  @override
  Future<ReelSource> call(Reel params) => _repository.resolve(params);
}

final class CacheReelVideo implements UseCase<void, Reel> {
  CacheReelVideo(this._repository);

  final ReelMediaRepository _repository;

  @override
  Future<void> call(Reel params) => _repository.cache(params);
}

final class MarkReelPlayed implements UseCase<void, String> {
  MarkReelPlayed(this._repository);

  final ReelMediaRepository _repository;

  @override
  Future<void> call(String params) => _repository.markPlayed(params);
}

final class KeepReelDownloads {
  KeepReelDownloads(this._repository);

  final ReelMediaRepository _repository;

  void call(Set<String> episodeIds) => _repository.keepDownloads(episodeIds);
}
