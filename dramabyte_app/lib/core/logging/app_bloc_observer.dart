import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<Object?> bloc) {
    AppLogger.debug('Created ${bloc.runtimeType}');
    super.onCreate(bloc);
  }

  @override
  void onChange(BlocBase<Object?> bloc, Change<Object?> change) {
    AppLogger.debug('${bloc.runtimeType} changed');
    super.onChange(bloc, change);
  }

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error(
      '${bloc.runtimeType} failed',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}
