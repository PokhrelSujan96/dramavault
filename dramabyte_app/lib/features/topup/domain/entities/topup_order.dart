import 'package:equatable/equatable.dart';

class TopupOrder extends Equatable {
  const TopupOrder({
    required this.id,
    required this.packageId,
    required this.status,
    this.coins = 0,
    this.bonusCoins = 0,
  });

  final String id;
  final String packageId;
  final String status;
  final int coins;
  final int bonusCoins;

  bool get isCompleted => status == 'completed';

  @override
  List<Object> get props => [id, packageId, status, coins, bonusCoins];
}
