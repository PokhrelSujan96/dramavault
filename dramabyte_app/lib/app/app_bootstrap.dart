import 'package:dramabyte_app/app/app.dart';
import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/logging/app_bloc_observer.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/security/app_security.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class AppBootstrap {
  static Future<void> initialize() async {
    FlutterError.onError = _handleFlutterError;
    PlatformDispatcher.instance.onError = _handlePlatformError;
    Bloc.observer = AppBlocObserver();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await configureDependencies();
    await getIt<AppSecurity>().initialize();
    final auth = getIt<AuthenticationBloc>()
      ..add(const AuthenticationStarted());
    await auth.stream.firstWhere((state) => state is! AuthenticationInitial);
    runApp(const DramaByteApp());
  }

  static void _handleFlutterError(FlutterErrorDetails details) {
    AppLogger.fatal(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  static bool _handlePlatformError(Object error, StackTrace stackTrace) {
    AppLogger.fatal('Platform error', error: error, stackTrace: stackTrace);
    return true;
  }
}
