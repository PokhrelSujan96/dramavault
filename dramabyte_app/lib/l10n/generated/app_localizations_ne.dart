// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get settings => 'सेटिङहरू';

  @override
  String get sectionPreferences => 'प्राथमिकताहरू';

  @override
  String get sectionPrivacy => 'गोपनीयता';

  @override
  String get sectionAccount => 'खाता';

  @override
  String get appearance => 'स्वरूप';

  @override
  String get appearanceSystem => 'प्रणाली पूर्वनिर्धारित';

  @override
  String get appearanceLight => 'लाइट';

  @override
  String get appearanceDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'प्रणाली पूर्वनिर्धारित';

  @override
  String get clearCache => 'क्यास खाली गर्नुहोस्';

  @override
  String get cacheCalculating => 'गणना हुँदैछ…';

  @override
  String get clearCacheBody =>
      'डाउनलोड गरिएका एपिसोड र सुरक्षित गरिएका तस्बिरहरू हटाइनेछन्। तपाईंको खाता र लाइब्रेरी अपरिवर्तित रहनेछन्।';

  @override
  String get clearCacheDone => 'क्यास खाली भयो';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get clear => 'खाली गर्नुहोस्';

  @override
  String get marketing => 'मार्केटिङ सञ्चार';

  @override
  String get marketingSubtitle =>
      'अफरहरू, नयाँ शृङ्खला र अपडेटहरू। जुनसुकै बेला परिवर्तन गर्नुहोस्।';

  @override
  String get privacyManagement => 'गोपनीयता व्यवस्थापन';

  @override
  String get privacySubtitle => 'कुकीहरू र डेटा विकल्पहरू';

  @override
  String get privacyIntro =>
      'DramaByte ले कुकीहरू र समान प्रविधिहरू कसरी प्रयोग गर्न सक्छ भन्ने छनोट गर्नुहोस्। तपाईं यसलाई जुनसुकै बेला परिवर्तन गर्न सक्नुहुन्छ।';

  @override
  String get privacyEssential => 'अत्यावश्यक';

  @override
  String get privacyEssentialBody =>
      'साइन-इन, सुरक्षा र प्लेब्याक। सधैँ सक्रिय।';

  @override
  String get privacyAnalytics => 'विश्लेषण';

  @override
  String get privacyAnalyticsBody =>
      'बगहरू फेला पार्न र एप सुधार्न मद्दत गर्छ।';

  @override
  String get privacyPersonalization => 'वैयक्तिकरण';

  @override
  String get privacyPersonalizationBody =>
      'तपाईंले हेरेका कुराका आधारमा शृङ्खला सिफारिस गर्नुहोस्।';

  @override
  String get membership => 'सदस्यता व्यवस्थापन';

  @override
  String membershipActive(int days) {
    return 'VIP · $days दिन बाँकी';
  }

  @override
  String get membershipFree => 'निःशुल्क योजना';

  @override
  String get membershipFreeBody =>
      'तपाईं VIP सदस्य हुनुहुन्न। प्रिमियम एपिसोड अनलक गर्न कोइन टपअप गर्नुहोस्।';

  @override
  String get membershipManageBody =>
      'सदस्यताको बिलिङ र रद्द तपाईंको एप स्टोर खाताबाट हुन्छ।';

  @override
  String get manageSubscription => 'सदस्यता व्यवस्थापन गर्नुहोस्';

  @override
  String get getCoins => 'कोइन टपअप';

  @override
  String get about => 'बारेमा';

  @override
  String aboutVersion(String version, String build) {
    return 'संस्करण $version ($build)';
  }

  @override
  String get termsOfService => 'सेवाका सर्तहरू';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get licenses => 'ओपन-सोर्स इजाजतपत्रहरू';

  @override
  String get deleteAccount => 'खाता मेटाउनुहोस्';

  @override
  String get deleteAccountSubtitle => 'आफ्नो डेटा स्थायी रूपमा हटाउनुहोस्';

  @override
  String get deleteWarning =>
      'यो फिर्ता गर्न सकिँदैन। तपाईंको प्रोफाइल, कोइन, लाइब्रेरी, इतिहास र रेटिङहरू हटाइनेछन् र तपाईं साइन आउट हुनुहुनेछ।';

  @override
  String deleteTypeToConfirm(String word) {
    return 'पुष्टि गर्न $word टाइप गर्नुहोस्';
  }

  @override
  String get deleteConfirm => 'Google बाट प्रमाणित गरी मेटाउनुहोस्';

  @override
  String get deleteFailed => 'खाता मेटाउन सकिएन। कृपया फेरि प्रयास गर्नुहोस्।';

  @override
  String get savedOffline =>
      'यस उपकरणमा सुरक्षित गरियो। अनलाइन हुँदा सिङ्क हुनेछ।';

  @override
  String clearCacheSize(String size) {
    return '$size प्रयोगमा';
  }
}
