import 'dart:convert';

import 'package:dramabyte_app/core/security/secure_storage.dart';
import 'package:dramabyte_app/features/settings/data/datasources/account_remote_source.dart';
import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/domain/repositories/consent_repository.dart';

final class ConsentRepositoryImpl implements ConsentRepository {
  ConsentRepositoryImpl(this._storage, this._remote);

  static const _key = 'consent_preferences';

  final SecureStorage _storage;
  final AccountRemoteSource _remote;

  @override
  Future<StoredConsent?> stored() async {
    final raw = await _storage.read(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return (preferences: _parse(json), pending: json['pending'] == true);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> store(ConsentPreferences preferences, {required bool pending}) {
    return _storage.write(
      _key,
      jsonEncode({..._body(preferences), 'pending': pending}),
    );
  }

  @override
  Future<bool> push(ConsentPreferences preferences) async {
    try {
      await _remote.savePreferences(_body(preferences));
      await store(preferences, pending: false);
      return true;
    } on Object {
      return false;
    }
  }

  @override
  Future<ConsentPreferences?> fetch() async {
    try {
      final json = await _remote.preferences();
      return _parse(json);
    } on Object {
      return null;
    }
  }

  static ConsentPreferences _parse(Map<String, dynamic> json) {
    return ConsentPreferences(
      marketing: json['marketing'] == true,
      analytics: json['analytics'] == true,
      personalization: json['personalization'] == true,
    );
  }

  static Map<String, bool> _body(ConsentPreferences preferences) => {
    'marketing': preferences.marketing,
    'analytics': preferences.analytics,
    'personalization': preferences.personalization,
  };
}
