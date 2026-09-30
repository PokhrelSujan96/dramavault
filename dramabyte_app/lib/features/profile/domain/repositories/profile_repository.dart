import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> cached(String userId);
  Future<UserProfile> fetch(String userId);
  Stream<void> changes(String userId);
}
