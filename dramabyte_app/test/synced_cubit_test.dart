import 'dart:async';

import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/authentication/domain/entities/auth_user.dart';
import 'package:dramabyte_app/features/authentication/domain/repositories/auth_repository.dart';
import 'package:dramabyte_app/features/authentication/domain/usecases/auth_use_cases.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth implements AuthRepository {
  @override
  Future<AuthUser?> cachedUser() async => const AuthUser('u1');

  @override
  Future<AuthUser?> restoreSession() async => const AuthUser('u1');

  @override
  Future<AuthUser?> signInWithGoogle(String? referralCode) async => null;

  @override
  Future<void> signOut() async {}
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late AuthenticationBloc auth;
  late StreamController<void> changes;
  late int fetches;
  String? cached;

  SyncedCubit<String> build() => SyncedCubit<String>(
    auth,
    readCache: (_) async => cached,
    fetch: (_) async => 'fresh${++fetches}',
    changes: (_) => changes.stream,
  );

  setUp(() {
    final repository = _FakeAuth();
    auth = AuthenticationBloc(
      RestoreSession(repository),
      SignInWithGoogle(repository),
      SignOut(repository),
      GetCachedUser(repository),
      const Stream.empty(),
    );
    changes = StreamController<void>.broadcast();
    fetches = 0;
    cached = null;
  });

  test('shows cached value first, then refreshes once silently', () async {
    cached = 'cached';
    final cubit = build();
    final states = <ResourceState<String>>[];
    cubit.stream.listen(states.add);
    auth.add(const AuthenticationStarted());
    await _settle();
    expect(states.first, const ResourceLoaded<String>('cached'));
    expect(states.last, const ResourceLoaded<String>('fresh1'));
    expect(states.whereType<ResourceLoading<String>>(), isEmpty);
    expect(fetches, 1);
  });

  test('refetches only when the database reports a change', () async {
    final cubit = build();
    auth.add(const AuthenticationStarted());
    await _settle();
    expect(fetches, 1);
    changes.add(null);
    await _settle();
    expect(fetches, 2);
    expect(cubit.state, const ResourceLoaded<String>('fresh2'));
  });

  test(
    'optimistic update applies instantly, then the server reconciles',
    () async {
      final cubit = build();
      auth.add(const AuthenticationStarted());
      await _settle();
      cubit.update((value) => '$value+optimistic');
      expect(cubit.state, const ResourceLoaded<String>('fresh1+optimistic'));
      await cubit.refresh();
      expect(cubit.state, const ResourceLoaded<String>('fresh2'));
    },
  );

  test('clears state on sign out', () async {
    final cubit = build();
    auth.add(const AuthenticationStarted());
    await _settle();
    auth.add(const SignOutRequested());
    await _settle();
    expect(cubit.state, isA<ResourceLoading<String>>());
    changes.add(null);
    await _settle();
    expect(fetches, 1);
  });
}
