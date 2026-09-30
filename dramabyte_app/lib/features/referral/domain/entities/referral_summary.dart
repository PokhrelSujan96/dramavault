import 'package:equatable/equatable.dart';

class ReferralSummary extends Equatable {
  const ReferralSummary({
    required this.code,
    this.invited = 0,
    this.purchased = 0,
    this.earned = 0,
    this.redeemed = false,
    this.signupReward = 0,
    this.purchaseReward = 0,
  });

  final String code;
  final int invited;
  final int purchased;
  final int earned;
  final bool redeemed;
  final int signupReward;
  final int purchaseReward;

  @override
  List<Object> get props => [
    code,
    invited,
    purchased,
    earned,
    redeemed,
    signupReward,
    purchaseReward,
  ];
}
