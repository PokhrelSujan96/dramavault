import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

abstract final class AppConfig {
  static const appName = 'DramaByte';
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const _lanHost = String.fromEnvironment(
    'DEV_LAN_HOST',
    defaultValue: 'Sujans-MacBook-Air.local',
  );
  static String get _devHost {
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    final isSimulator =
        Platform.isIOS &&
        Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');
    return Platform.isIOS && !isSimulator ? _lanHost : '127.0.0.1';
  }

  static String get apiBaseUrl {
    if (_apiBaseUrlOverride.isNotEmpty) return _apiBaseUrlOverride;
    return 'http://$_devHost:8000/api/v1';
  }

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aoalgtqryqkgxkmjceia.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFvYWxndHFyeXFrZ3hrbWpjZWlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2MTQ1ODEsImV4cCI6MjEwNjE5MDU4MX0.JGU1r1YKIfhvYibKsygOji4V7wJuPaDqib5KCIdTloE',
  );
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '108339124222-621qp9q4tfq77so7fhierdo1b8o01u0e.apps.googleusercontent.com',
  );
  static const googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '108339124222-f463i6q5fbq6h51lcgj3sto3f0n8nkbt.apps.googleusercontent.com',
  );
  static const termsUrl = String.fromEnvironment('TERMS_URL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const connectTimeout = Duration(seconds: 20);
  static const receiveTimeout = Duration(seconds: 20);
  static const sendTimeout = Duration(seconds: 20);
  static const designSize = Size(393, 852);
  static const isProduction = environment == 'production';
}
