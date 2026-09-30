import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ne.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('ne'),
    Locale('pl'),
    Locale('zh'),
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get sectionPreferences;

  /// No description provided for @sectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get sectionPrivacy;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @appearanceSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get appearanceSystem;

  /// No description provided for @appearanceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCache;

  /// No description provided for @cacheCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating…'**
  String get cacheCalculating;

  /// No description provided for @clearCacheBody.
  ///
  /// In en, this message translates to:
  /// **'Downloaded episodes and saved images will be removed. Your account and library stay untouched.'**
  String get clearCacheBody;

  /// No description provided for @clearCacheDone.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get clearCacheDone;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing communications'**
  String get marketing;

  /// No description provided for @marketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offers, new series and updates. Change it any time.'**
  String get marketingSubtitle;

  /// No description provided for @privacyManagement.
  ///
  /// In en, this message translates to:
  /// **'Privacy management'**
  String get privacyManagement;

  /// No description provided for @privacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cookies and data choices'**
  String get privacySubtitle;

  /// No description provided for @privacyIntro.
  ///
  /// In en, this message translates to:
  /// **'Choose how DramaByte may use cookies and similar technologies. You can change this at any time.'**
  String get privacyIntro;

  /// No description provided for @privacyEssential.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get privacyEssential;

  /// No description provided for @privacyEssentialBody.
  ///
  /// In en, this message translates to:
  /// **'Sign-in, security and playback. Always on.'**
  String get privacyEssentialBody;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get privacyAnalytics;

  /// No description provided for @privacyAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Helps us find bugs and improve the app.'**
  String get privacyAnalyticsBody;

  /// No description provided for @privacyPersonalization.
  ///
  /// In en, this message translates to:
  /// **'Personalisation'**
  String get privacyPersonalization;

  /// No description provided for @privacyPersonalizationBody.
  ///
  /// In en, this message translates to:
  /// **'Recommend series based on what you watch.'**
  String get privacyPersonalizationBody;

  /// No description provided for @membership.
  ///
  /// In en, this message translates to:
  /// **'Manage membership'**
  String get membership;

  /// No description provided for @membershipActive.
  ///
  /// In en, this message translates to:
  /// **'VIP · {days} days left'**
  String membershipActive(int days);

  /// No description provided for @membershipFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get membershipFree;

  /// No description provided for @membershipFreeBody.
  ///
  /// In en, this message translates to:
  /// **'You are not a VIP member. Top up coins to unlock premium episodes.'**
  String get membershipFreeBody;

  /// No description provided for @membershipManageBody.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are billed and cancelled through your app store account.'**
  String get membershipManageBody;

  /// No description provided for @manageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get manageSubscription;

  /// No description provided for @getCoins.
  ///
  /// In en, this message translates to:
  /// **'Top up coins'**
  String get getCoins;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} ({build})'**
  String aboutVersion(String version, String build);

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get licenses;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove your data'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Your profile, coins, library, history and ratings will be removed and you will be signed out.'**
  String get deleteWarning;

  /// No description provided for @deleteTypeToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String deleteTypeToConfirm(String word);

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Verify with Google and delete'**
  String get deleteConfirm;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete your account. Please try again.'**
  String get deleteFailed;

  /// No description provided for @savedOffline.
  ///
  /// In en, this message translates to:
  /// **'Saved on this device. We will sync it when you are back online.'**
  String get savedOffline;

  /// No description provided for @clearCacheSize.
  ///
  /// In en, this message translates to:
  /// **'{size} used'**
  String clearCacheSize(String size);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'hi',
    'ja',
    'ko',
    'ne',
    'pl',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'ne':
      return AppLocalizationsNe();
    case 'pl':
      return AppLocalizationsPl();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
