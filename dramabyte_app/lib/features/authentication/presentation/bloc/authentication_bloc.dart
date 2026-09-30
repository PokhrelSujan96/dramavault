import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/usecases/auth_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';

class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  AuthenticationBloc(
    this._restore,
    this._google,
    this._signOut,
    this._cachedUser,
    Stream<void> sessionExpired,
  ) : super(AuthenticationInitial()) {
    on<AuthenticationStarted>(_onStarted);
    on<GoogleSignInRequested>(_onGoogle);
    on<SignOutRequested>(_onSignOut);
    on<SessionExpired>(_onExpired);
    _expiredSubscription = sessionExpired.listen(
      (_) => add(const SessionExpired()),
    );
  }

  final RestoreSession _restore;
  final SignInWithGoogle _google;
  final SignOut _signOut;
  final GetCachedUser _cachedUser;
  late final StreamSubscription<void> _expiredSubscription;

  Future<void> _onStarted(
    AuthenticationStarted event,
    Emitter<AuthenticationState> emit,
  ) async {
    final user = await _cachedUser(const NoParams());
    if (user == null) return emit(const Unauthenticated());
    emit(Authenticated(user));
    unawaited(_verifySession());
  }

  Future<void> _onGoogle(
    GoogleSignInRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (state is AuthenticationLoading) return;
    emit(AuthenticationLoading());
    try {
      final user = await _google(event.referralCode);
      emit(user == null ? const Unauthenticated() : Authenticated(user));
    } on Failure catch (failure) {
      emit(Unauthenticated(message: failure.message));
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Authentication failed',
        error: error,
        stackTrace: stackTrace,
      );
      emit(const Unauthenticated(message: 'Sign-in failed. Please try again.'));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const Unauthenticated());
    await _cleanUp();
  }

  Future<void> _onExpired(
    SessionExpired event,
    Emitter<AuthenticationState> emit,
  ) async {
    if (state is! Authenticated) return;
    emit(
      const Unauthenticated(
        message: 'Your session expired. Please sign in again.',
      ),
    );
    await _cleanUp();
  }

  Future<void> _verifySession() async {
    try {
      if (await _restore(const NoParams()) == null) add(const SessionExpired());
    } on Failure {
      return;
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Session check failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _cleanUp() async {
    try {
      await _signOut(const NoParams());
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Sign-out cleanup failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> close() {
    _expiredSubscription.cancel();
    return super.close();
  }
}
