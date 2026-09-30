// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get sectionPreferences => 'Preferences';

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get sectionAccount => 'Account';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSystem => 'System default';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get clearCache => 'Clear cache';

  @override
  String get cacheCalculating => 'Calculating…';

  @override
  String get clearCacheBody =>
      'Downloaded episodes and saved images will be removed. Your account and library stay untouched.';

  @override
  String get clearCacheDone => 'Cache cleared';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get marketing => 'Marketing communications';

  @override
  String get marketingSubtitle =>
      'Offers, new series and updates. Change it any time.';

  @override
  String get privacyManagement => 'Privacy management';

  @override
  String get privacySubtitle => 'Cookies and data choices';

  @override
  String get privacyIntro =>
      'Choose how DramaByte may use cookies and similar technologies. You can change this at any time.';

  @override
  String get privacyEssential => 'Essential';

  @override
  String get privacyEssentialBody =>
      'Sign-in, security and playback. Always on.';

  @override
  String get privacyAnalytics => 'Analytics';

  @override
  String get privacyAnalyticsBody => 'Helps us find bugs and improve the app.';

  @override
  String get privacyPersonalization => 'Personalisation';

  @override
  String get privacyPersonalizationBody =>
      'Recommend series based on what you watch.';

  @override
  String get membership => 'Manage membership';

  @override
  String membershipActive(int days) {
    return 'VIP · $days days left';
  }

  @override
  String get membershipFree => 'Free plan';

  @override
  String get membershipFreeBody =>
      'You are not a VIP member. Top up coins to unlock premium episodes.';

  @override
  String get membershipManageBody =>
      'Subscriptions are billed and cancelled through your app store account.';

  @override
  String get manageSubscription => 'Manage subscription';

  @override
  String get getCoins => 'Top up coins';

  @override
  String get about => 'About';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get termsOfService => 'Terms of service';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get licenses => 'Open-source licences';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountSubtitle => 'Permanently remove your data';

  @override
  String get deleteWarning =>
      'This cannot be undone. Your profile, coins, library, history and ratings will be removed and you will be signed out.';

  @override
  String deleteTypeToConfirm(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get deleteConfirm => 'Verify with Google and delete';

  @override
  String get deleteFailed => 'Could not delete your account. Please try again.';

  @override
  String get savedOffline =>
      'Saved on this device. We will sync it when you are back online.';

  @override
  String clearCacheSize(String size) {
    return '$size used';
  }
}
