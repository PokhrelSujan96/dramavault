import 'dart:async';

import 'package:dramabyte_app/app/app_bootstrap.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await AppBootstrap.initialize();
    },
    (error, stackTrace) => AppLogger.fatal(
      'Uncaught zone error',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}
