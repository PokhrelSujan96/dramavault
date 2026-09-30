import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/features/profile/domain/repositories/profile_repository.dart';

final class GetCachedProfile implements UseCase<UserProfile?, String> {
  GetCachedProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<UserProfile?> call(String params) => _repository.cached(params);
}

final class GetMyProfile implements UseCase<UserProfile, String> {
  GetMyProfile(this._repository);

  final ProfileRepository _repository;

  @override
  Future<UserProfile> call(String params) => _repository.fetch(params);
}

final class WatchProfileChanges {
  WatchProfileChanges(this._repository);

  final ProfileRepository _repository;

  Stream<void> call(String userId) => _repository.changes(userId);
}
