import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';

final class ReferralSummaryModel {
  const ReferralSummaryModel(this._json);

  final Map<String, dynamic> _json;

  Map<String, dynamic> get json => _json;

  ReferralSummary toEntity() => ReferralSummary(
    code: _json['code'] is String ? _json['code'] as String : '',
    invited: _int('invited'),
    purchased: _int('purchased'),
    earned: _int('earned'),
    redeemed: _json['redeemed'] == true,
    signupReward: _int('signup_reward'),
    purchaseReward: _int('purchase_reward'),
  );

  int _int(String key) {
    final value = _json[key];
    return value is num ? value.toInt() : 0;
  }
}
