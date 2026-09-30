import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

final class GoogleSignInSource {
  bool _initialized = false;

  Future<String?> idToken() async {
    final google = GoogleSignIn.instance;
    if (!_initialized) {
      await google.initialize(
        serverClientId: AppConfig.googleServerClientId,
        clientId: AppConfig.googleIosClientId.isEmpty
            ? null
            : AppConfig.googleIosClientId,
      );
      _initialized = true;
    }
    try {
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw const UnknownFailure('Google did not return an identity token');
      }
      return token;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      throw UnknownFailure(error.description ?? 'Google sign-in failed');
    } on PlatformException catch (error) {
      throw NetworkFailure(
        'Could not complete Google sign-in: ${error.message ?? error.code}',
      );
    }
  }

  Future<void> signOut() => GoogleSignIn.instance.signOut();
}
