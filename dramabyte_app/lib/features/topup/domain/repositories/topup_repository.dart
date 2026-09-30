import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';

abstract interface class TopupRepository {
  Future<List<CoinPackage>?> cachedPackages();
  Future<List<CoinPackage>> packages();
  Stream<void> packageChanges();
  Future<TopupOrder> createOrder(String packageId);
  Future<TopupOrder> confirm(String orderId, String? receipt);
}
