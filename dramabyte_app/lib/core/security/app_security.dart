import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:flutter/services.dart';

final class AppSecurity {
  static const _channel = MethodChannel('com.dramabyte.app/security');

  Future<void> initialize() async {
    try {
      await _channel.invokeMethod<void>('enableSecureMode');
    } on MissingPluginException {
      AppLogger.debug('Native secure mode is unavailable on this platform');
    } on PlatformException catch (error, stackTrace) {
      AppLogger.warning(
        'Native secure mode could not be enabled',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
