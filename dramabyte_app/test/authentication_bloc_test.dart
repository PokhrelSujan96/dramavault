import 'dart:async';

import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dramabyte_app/features/authentication/domain/usecases/auth_use_cases.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements AuthRepository {
  AuthUser? cached = const AuthUser('u1');
  Completer<AuthUser?> restore = Completer();
  bool signedOut = false;

  @override
  Future<AuthUser?> cachedUser() async => cached;

  @override
  Future<AuthUser?> restoreSession() => restore.future;

  @override
  Future<AuthUser?> signInWithGoogle(String? referralCode) async => null;

  @override
  Future<void> signOut() async => signedOut = true;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late _FakeAuth repository;
  late StreamController<void> expired;
  late AuthenticationBloc bloc;

  setUp(() {
    repository = _FakeAuth();
    expired = StreamController<void>.broadcast();
    bloc = AuthenticationBloc(
      RestoreSession(repository),
      SignInWithGoogle(repository),
      SignOut(repository),
      GetCachedUser(repository),
      expired.stream,
    );
  });

  test('starts signed in immediately, before the network answers', () async {
    bloc.add(const AuthenticationStarted());
    await _settle();
    expect(bloc.state, const Authenticated(AuthUser('u1')));
    expect(repository.restore.isCompleted, isFalse);
  });

  test('starts signed out when there is no stored session', () async {
    repository.cached = null;
    bloc.add(const AuthenticationStarted());
    await _settle();
    expect(bloc.state, isA<Unauthenticated>());
  });

  test('a rejected session signs the user out with a message', () async {
    bloc.add(const AuthenticationStarted());
    await _settle();
    repository.restore.complete(null);
    await _settle();
    expect(bloc.state, isA<Unauthenticated>());
    expect((bloc.state as Unauthenticated).message, contains('expired'));
    expect(repository.signedOut, isTrue);
  });

  test('being offline keeps the user signed in', () async {
    bloc.add(const AuthenticationStarted());
    await _settle();
    repository.restore.completeError(const NetworkFailure('offline'));
    await _settle();
    expect(bloc.state, const Authenticated(AuthUser('u1')));
  });

  test('a session that dies mid-use signs the user out', () async {
    bloc.add(const AuthenticationStarted());
    await _settle();
    expired.add(null);
    await _settle();
    expect(bloc.state, isA<Unauthenticated>());
  });

  test('sign out is instant and cleans up afterwards', () async {
    bloc.add(const AuthenticationStarted());
    await _settle();
    bloc.add(const SignOutRequested());
    await _settle();
    expect(bloc.state, isA<Unauthenticated>());
    expect(repository.signedOut, isTrue);
  });
}
