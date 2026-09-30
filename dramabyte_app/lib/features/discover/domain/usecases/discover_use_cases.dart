import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';
import 'package:dramabyte_app/features/discover/domain/repositories/discover_repository.dart';

final class GetReelPage implements UseCase<ReelPage, String?> {
  GetReelPage(this._repository);

  final DiscoverRepository _repository;

  @override
  Future<ReelPage> call(String? params) =>
      _repository.fetchPage(cursor: params);
}

final class GetCachedReelPage implements UseCase<ReelPage?, NoParams> {
  GetCachedReelPage(this._repository);

  final DiscoverRepository _repository;

  @override
  Future<ReelPage?> call(NoParams params) => _repository.cachedFirstPage();
}

final class GetOfflineReels implements UseCase<List<Reel>, NoParams> {
  GetOfflineReels(this._repository);

  final DiscoverRepository _repository;

  @override
  Future<List<Reel>> call(NoParams params) => _repository.offlineReels();
}
