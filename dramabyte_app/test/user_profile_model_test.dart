import 'package:dramabyte_app/features/profile/data/models/user_profile_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a full payload', () {
    final profile = UserProfileModel(const {
      'id': 'u1',
      'display_name': 'Sujan',
      'coins': 10,
      'bonus_coins': 5,
      'is_vip': true,
      'vip_expires_at': '2030-01-01T00:00:00Z',
    }).toEntity();
    expect(profile.name, 'Sujan');
    expect(profile.totalCoins, 15);
    expect(profile.isVip, isTrue);
  });

  test('survives missing, extra and wrongly typed fields', () {
    final profile = UserProfileModel(const {
      'id': 'u1',
      'coins': 'oops',
      'new_backend_field': {'a': 1},
      'vip_expires_at': 42,
    }).toEntity();
    expect(profile.coins, 0);
    expect(profile.language, 'en');
    expect(profile.vipExpiresAt, isNull);
    expect(profile.name, 'DramaByte user');
  });
}
