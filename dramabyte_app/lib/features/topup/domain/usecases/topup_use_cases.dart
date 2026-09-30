import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';
import 'package:dramabyte_app/features/topup/domain/repositories/topup_repository.dart';

final class GetCoinPackages implements UseCase<List<CoinPackage>, NoParams> {
  GetCoinPackages(this._repository);

  final TopupRepository _repository;

  @override
  Future<List<CoinPackage>> call(NoParams params) => _repository.packages();
}

final class GetCachedCoinPackages
    implements UseCase<List<CoinPackage>?, NoParams> {
  GetCachedCoinPackages(this._repository);

  final TopupRepository _repository;

  @override
  Future<List<CoinPackage>?> call(NoParams params) =>
      _repository.cachedPackages();
}

final class WatchCoinPackageChanges {
  WatchCoinPackageChanges(this._repository);

  final TopupRepository _repository;

  Stream<void> call() => _repository.packageChanges();
}

final class CreateTopupOrder implements UseCase<TopupOrder, String> {
  CreateTopupOrder(this._repository);

  final TopupRepository _repository;

  @override
  Future<TopupOrder> call(String params) => _repository.createOrder(params);
}

final class ConfirmParams {
  const ConfirmParams(this.orderId, this.receipt);

  final String orderId;
  final String? receipt;
}

final class ConfirmTopup implements UseCase<TopupOrder, ConfirmParams> {
  ConfirmTopup(this._repository);

  final TopupRepository _repository;

  @override
  Future<TopupOrder> call(ConfirmParams params) =>
      _repository.confirm(params.orderId, params.receipt);
}
