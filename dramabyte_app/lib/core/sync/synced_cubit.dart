import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:equatable/equatable.dart';

sealed class ResourceState<T> extends Equatable {
  const ResourceState();

  @override
  List<Object?> get props => [];
}

final class ResourceLoading<T> extends ResourceState<T> {
  const ResourceLoading();
}

final class ResourceLoaded<T> extends ResourceState<T> {
  const ResourceLoaded(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class ResourceError<T> extends ResourceState<T> {
  const ResourceError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class SyncedCubit<T> extends Cubit<ResourceState<T>> {
  SyncedCubit(
    AuthenticationBloc auth, {
    required this.readCache,
    required this.fetch,
    required this.changes,
  }) : super(ResourceLoading<T>()) {
    _authSubscription = auth.stream.listen(_onAuth);
    _onAuth(auth.state);
  }

  final Future<T?> Function(String userId) readCache;
  final Future<T> Function(String userId) fetch;
  final Stream<void> Function(String userId) changes;
  late final StreamSubscription<AuthenticationState> _authSubscription;
  StreamSubscription<void>? _changesSubscription;
  String? _userId;
  bool _refreshing = false;
  bool _dirty = false;

  Future<void> refresh() async {
    final userId = _userId;
    if (userId == null) return;
    if (_refreshing) {
      _dirty = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _dirty = false;
        try {
          emit(ResourceLoaded(await fetch(userId)));
        } on Failure catch (failure) {
          if (state is! ResourceLoaded<T>) {
            emit(ResourceError<T>(failure.message));
          }
        }
      } while (_dirty && _userId == userId);
    } finally {
      _refreshing = false;
    }
  }

  void update(T Function(T current) transform) {
    final current = state;
    if (current is ResourceLoaded<T>) {
      emit(ResourceLoaded<T>(transform(current.value)));
    }
  }

  Future<void> retry() {
    emit(ResourceLoading<T>());
    return refresh();
  }

  void _onAuth(AuthenticationState auth) {
    if (auth is Authenticated && auth.user.id != _userId) {
      unawaited(_start(auth.user.id));
    } else if (auth is Unauthenticated) {
      _stop();
    }
  }

  Future<void> _start(String userId) async {
    await _changesSubscription?.cancel();
    _userId = userId;
    final cached = await readCache(userId);
    if (_userId != userId) return;
    if (cached != null) emit(ResourceLoaded(cached));
    _changesSubscription = changes(userId).listen((_) => refresh());
    await refresh();
  }

  void _stop() {
    _changesSubscription?.cancel();
    _changesSubscription = null;
    _userId = null;
    emit(ResourceLoading<T>());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    _changesSubscription?.cancel();
    return super.close();
  }
}
