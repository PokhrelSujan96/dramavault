import 'package:equatable/equatable.dart';

class CoinPackage extends Equatable {
  const CoinPackage({
    required this.id,
    required this.coins,
    this.bonusCoins = 0,
    this.priceCents = 0,
    this.currency = 'USD',
  });

  final String id;
  final int coins;
  final int bonusCoins;
  final int priceCents;
  final String currency;

  int get totalCoins => coins + bonusCoins;

  String get priceLabel {
    final symbol = const {'USD': r'$', 'EUR': '€', 'GBP': '£'}[currency];
    final amount = (priceCents / 100).toStringAsFixed(2);
    return symbol == null ? '$currency $amount' : '$symbol$amount';
  }

  @override
  List<Object> get props => [id, coins, bonusCoins, priceCents, currency];
}
