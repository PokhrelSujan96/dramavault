import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';

final class UserProfileModel {
  const UserProfileModel(this._json);

  final Map<String, dynamic> _json;

  Map<String, dynamic> get json => _json;

  UserProfile toEntity() => UserProfile(
    id: _string('id') ?? '',
    displayName: _string('display_name') ?? '',
    email: _string('email'),
    avatarUrl: _string('avatar_url'),
    country: _string('country'),
    language: _string('language') ?? 'en',
    coins: _int('coins'),
    bonusCoins: _int('bonus_coins'),
    isVip: _json['is_vip'] == true,
    vipExpiresAt: DateTime.tryParse(_string('vip_expires_at') ?? ''),
    isOnboarded: _json['is_onboarded'] == true,
  );

  String? _string(String key) {
    final value = _json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _int(String key) {
    final value = _json[key];
    return value is num ? value.toInt() : 0;
  }
}
