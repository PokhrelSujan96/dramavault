import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/consent_repository.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeConsent implements ConsentRepository {
  StoredConsent? saved;
  ConsentPreferences? remote;
  bool online = true;
  int pushes = 0;

  @override
  Future<StoredConsent?> stored() async => saved;

  @override
  Future<void> store(
    ConsentPreferences preferences, {
    required bool pending,
  }) async {
    saved = (preferences: preferences, pending: pending);
  }

  @override
  Future<bool> push(ConsentPreferences preferences) async {
    pushes++;
    if (!online) return false;
    saved = (preferences: preferences, pending: false);
    return true;
  }

  @override
  Future<ConsentPreferences?> fetch() async => remote;
}

void main() {
  test('a toggle applies instantly and syncs', () async {
    final repo = _FakeConsent();
    final cubit = ConsentCubit(repo);
    await cubit.set(ConsentPurpose.marketing, true);
    expect(cubit.state.preferences.marketing, isTrue);
    expect(cubit.state.offline, isFalse);
    expect(repo.saved!.pending, isFalse);
  });

  test('offline toggles stay local and retry on the next load', () async {
    final repo = _FakeConsent()..online = false;
    final cubit = ConsentCubit(repo);
    await cubit.set(ConsentPurpose.analytics, true);
    expect(cubit.state.offline, isTrue);
    expect(repo.saved!.pending, isTrue);

    repo.online = true;
    await cubit.load();
    expect(cubit.state.offline, isFalse);
    expect(repo.saved!.pending, isFalse);
  });

  test('first load adopts the server preferences', () async {
    final repo = _FakeConsent()
      ..remote = const ConsentPreferences(personalization: true);
    final cubit = ConsentCubit(repo);
    await cubit.load();
    expect(cubit.state.preferences.personalization, isTrue);
    expect(repo.saved!.pending, isFalse);
  });
}
