import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';
import 'package:dramabyte_app/features/topup/domain/gateways/payment_gateway.dart';

final class SandboxPaymentGateway implements PaymentGateway {
  @override
  Future<String?> pay(CoinPackage package, TopupOrder order) async => null;
}
