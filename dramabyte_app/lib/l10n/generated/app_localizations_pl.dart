// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get settings => 'Ustawienia';

  @override
  String get sectionPreferences => 'Preferencje';

  @override
  String get sectionPrivacy => 'Prywatność';

  @override
  String get sectionAccount => 'Konto';

  @override
  String get appearance => 'Wygląd';

  @override
  String get appearanceSystem => 'Domyślny systemu';

  @override
  String get appearanceLight => 'Jasny';

  @override
  String get appearanceDark => 'Ciemny';

  @override
  String get language => 'Język';

  @override
  String get languageSystem => 'Domyślny systemu';

  @override
  String get clearCache => 'Wyczyść pamięć podręczną';

  @override
  String get cacheCalculating => 'Obliczanie…';

  @override
  String get clearCacheBody =>
      'Pobrane odcinki i zapisane obrazy zostaną usunięte. Twoje konto i biblioteka pozostaną nienaruszone.';

  @override
  String get clearCacheDone => 'Pamięć podręczna wyczyszczona';

  @override
  String get cancel => 'Anuluj';

  @override
  String get clear => 'Wyczyść';

  @override
  String get marketing => 'Komunikacja marketingowa';

  @override
  String get marketingSubtitle =>
      'Oferty, nowe seriale i nowości. Możesz to zmienić w każdej chwili.';

  @override
  String get privacyManagement => 'Zarządzanie prywatnością';

  @override
  String get privacySubtitle => 'Pliki cookie i wybory dotyczące danych';

  @override
  String get privacyIntro =>
      'Wybierz, jak DramaByte może używać plików cookie i podobnych technologii. Możesz to zmienić w każdej chwili.';

  @override
  String get privacyEssential => 'Niezbędne';

  @override
  String get privacyEssentialBody =>
      'Logowanie, bezpieczeństwo i odtwarzanie. Zawsze włączone.';

  @override
  String get privacyAnalytics => 'Analityka';

  @override
  String get privacyAnalyticsBody =>
      'Pomaga nam znajdować błędy i ulepszać aplikację.';

  @override
  String get privacyPersonalization => 'Personalizacja';

  @override
  String get privacyPersonalizationBody =>
      'Polecaj seriale na podstawie tego, co oglądasz.';

  @override
  String get membership => 'Zarządzaj członkostwem';

  @override
  String membershipActive(int days) {
    return 'VIP · zostało $days dni';
  }

  @override
  String get membershipFree => 'Plan bezpłatny';

  @override
  String get membershipFreeBody =>
      'Nie jesteś członkiem VIP. Doładuj monety, aby odblokować odcinki premium.';

  @override
  String get membershipManageBody =>
      'Subskrypcjami zarządza się w koncie sklepu z aplikacjami.';

  @override
  String get manageSubscription => 'Zarządzaj subskrypcją';

  @override
  String get getCoins => 'Doładuj monety';

  @override
  String get about => 'O aplikacji';

  @override
  String aboutVersion(String version, String build) {
    return 'Wersja $version ($build)';
  }

  @override
  String get termsOfService => 'Regulamin';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get licenses => 'Licencje open source';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get deleteAccountSubtitle => 'Trwale usuń swoje dane';

  @override
  String get deleteWarning =>
      'Tej operacji nie można cofnąć. Twój profil, monety, biblioteka, historia i oceny zostaną usunięte, a Ty zostaniesz wylogowany.';

  @override
  String deleteTypeToConfirm(String word) {
    return 'Wpisz $word, aby potwierdzić';
  }

  @override
  String get deleteConfirm => 'Zweryfikuj przez Google i usuń';

  @override
  String get deleteFailed => 'Nie udało się usunąć konta. Spróbuj ponownie.';

  @override
  String get savedOffline =>
      'Zapisano na tym urządzeniu. Zsynchronizujemy po powrocie online.';

  @override
  String clearCacheSize(String size) {
    return 'Zajęte: $size';
  }
}
