import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/authentication/data/datasources/google_sign_in_source.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/account_repository.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/cache_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum DeleteStatus { idle, working, failed, done }

final class DeleteAccountCubit extends Cubit<DeleteStatus> {
  DeleteAccountCubit(this._accounts, this._google, this._cache)
    : super(DeleteStatus.idle);

  final AccountRepository _accounts;
  final GoogleSignInSource _google;
  final CacheRepository _cache;

  Future<void> confirm() async {
    if (state == DeleteStatus.working) return;
    emit(DeleteStatus.working);
    try {
      final token = await _google.idToken();
      if (token == null) return emit(DeleteStatus.idle);
      await _accounts.delete(token);
      await _cache.clear().catchError((Object _) {});
      emit(DeleteStatus.done);
    } on Failure {
      emit(DeleteStatus.failed);
    }
  }
}
