import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';

abstract interface class PaymentGateway {
  Future<String?> pay(CoinPackage package, TopupOrder order);
}
