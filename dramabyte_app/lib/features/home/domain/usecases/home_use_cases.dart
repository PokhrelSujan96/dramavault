import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/repositories/home_repository.dart';

final class GetCachedHome implements UseCase<HomeFeed?, NoParams> {
  GetCachedHome(this._repository);

  final HomeRepository _repository;

  @override
  Future<HomeFeed?> call(NoParams params) => _repository.cached();
}

final class GetHome implements UseCase<HomeFeed, NoParams> {
  GetHome(this._repository);

  final HomeRepository _repository;

  @override
  Future<HomeFeed> call(NoParams params) => _repository.fetch();
}
