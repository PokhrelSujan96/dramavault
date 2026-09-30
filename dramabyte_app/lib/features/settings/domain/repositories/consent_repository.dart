import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';

typedef StoredConsent = ({ConsentPreferences preferences, bool pending});

abstract interface class ConsentRepository {
  Future<StoredConsent?> stored();
  Future<void> store(ConsentPreferences preferences, {required bool pending});
  Future<bool> push(ConsentPreferences preferences);
  Future<ConsentPreferences?> fetch();
}
