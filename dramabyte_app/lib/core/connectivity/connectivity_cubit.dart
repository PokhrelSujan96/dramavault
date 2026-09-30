import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectionStatus { online, offline }

final class ConnectivityCubit extends Cubit<ConnectionStatus> {
  ConnectivityCubit(this._connectivity) : super(ConnectionStatus.online) {
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Future<void> check() async {
    _update(await _connectivity.checkConnectivity());
  }

  void _update(List<ConnectivityResult> results) {
    emit(
      results.contains(ConnectivityResult.none)
          ? ConnectionStatus.offline
          : ConnectionStatus.online,
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
