import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  return value is num ? value.toInt() : 0;
}

String _string(Map<String, dynamic> json, String key, [String fallback = '']) {
  final value = json[key];
  return value is String && value.isNotEmpty ? value : fallback;
}

final class CoinPackageModel {
  const CoinPackageModel(this._json);

  final Map<String, dynamic> _json;

  Map<String, dynamic> get json => _json;

  CoinPackage toEntity() => CoinPackage(
    id: _string(_json, 'id'),
    coins: _int(_json, 'coins'),
    bonusCoins: _int(_json, 'bonus_coins'),
    priceCents: _int(_json, 'price_cents'),
    currency: _string(_json, 'currency', 'USD'),
  );
}

final class TopupOrderModel {
  const TopupOrderModel(this._json);

  final Map<String, dynamic> _json;

  TopupOrder toEntity() => TopupOrder(
    id: _string(_json, 'id'),
    packageId: _string(_json, 'package_id'),
    status: _string(_json, 'status', 'pending'),
    coins: _int(_json, 'coins'),
    bonusCoins: _int(_json, 'bonus_coins'),
  );
}
