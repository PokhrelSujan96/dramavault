import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/settings/data/datasources/account_remote_source.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/account_repository.dart';

final class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote);

  final AccountRemoteSource _remote;

  @override
  Future<void> delete(String idToken) async {
    try {
      await _remote.delete(idToken);
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      throw code == 403
          ? const UnknownFailure('Re-authentication failed')
          : const NetworkFailure('Could not reach DramaByte');
    }
  }
}
