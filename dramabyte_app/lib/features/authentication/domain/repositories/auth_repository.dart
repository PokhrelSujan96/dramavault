import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> cachedUser();
  Future<AuthUser?> restoreSession();
  Future<AuthUser?> signInWithGoogle(String? referralCode);
  Future<void> signOut();
}
