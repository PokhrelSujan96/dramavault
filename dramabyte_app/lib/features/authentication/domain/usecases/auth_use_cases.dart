import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';

final class GetCachedUser implements UseCase<AuthUser?, NoParams> {
  GetCachedUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser?> call(NoParams params) => _repository.cachedUser();
}

final class RestoreSession implements UseCase<AuthUser?, NoParams> {
  RestoreSession(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser?> call(NoParams params) => _repository.restoreSession();
}

final class SignInWithGoogle implements UseCase<AuthUser?, String?> {
  SignInWithGoogle(this._repository);

  final AuthRepository _repository;

  @override
  Future<AuthUser?> call(String? params) =>
      _repository.signInWithGoogle(params);
}

final class SignOut implements UseCase<void, NoParams> {
  SignOut(this._repository);

  final AuthRepository _repository;

  @override
  Future<void> call(NoParams params) => _repository.signOut();
}
