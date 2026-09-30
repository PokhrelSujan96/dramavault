// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get sectionPreferences => 'प्राथमिकताएँ';

  @override
  String get sectionPrivacy => 'गोपनीयता';

  @override
  String get sectionAccount => 'खाता';

  @override
  String get appearance => 'दिखावट';

  @override
  String get appearanceSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get appearanceLight => 'लाइट';

  @override
  String get appearanceDark => 'डार्क';

  @override
  String get language => 'भाषा';

  @override
  String get languageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get clearCache => 'कैश साफ़ करें';

  @override
  String get cacheCalculating => 'गणना हो रही है…';

  @override
  String get clearCacheBody =>
      'डाउनलोड किए गए एपिसोड और सहेजी गई छवियाँ हट जाएँगी। आपका खाता और लाइब्रेरी सुरक्षित रहेंगे।';

  @override
  String get clearCacheDone => 'कैश साफ़ हो गया';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get clear => 'साफ़ करें';

  @override
  String get marketing => 'मार्केटिंग संचार';

  @override
  String get marketingSubtitle => 'ऑफ़र, नई सीरीज़ और अपडेट। कभी भी बदलें।';

  @override
  String get privacyManagement => 'गोपनीयता प्रबंधन';

  @override
  String get privacySubtitle => 'कुकीज़ और डेटा विकल्प';

  @override
  String get privacyIntro =>
      'चुनें कि DramaByte कुकीज़ और समान तकनीकों का उपयोग कैसे कर सकता है। आप इसे कभी भी बदल सकते हैं।';

  @override
  String get privacyEssential => 'आवश्यक';

  @override
  String get privacyEssentialBody => 'साइन-इन, सुरक्षा और प्लेबैक। हमेशा चालू।';

  @override
  String get privacyAnalytics => 'एनालिटिक्स';

  @override
  String get privacyAnalyticsBody =>
      'बग खोजने और ऐप को बेहतर बनाने में मदद करता है।';

  @override
  String get privacyPersonalization => 'वैयक्तिकरण';

  @override
  String get privacyPersonalizationBody =>
      'आप जो देखते हैं उसके आधार पर सीरीज़ सुझाएँ।';

  @override
  String get membership => 'सदस्यता प्रबंधित करें';

  @override
  String membershipActive(int days) {
    return 'VIP · $days दिन शेष';
  }

  @override
  String get membershipFree => 'निःशुल्क प्लान';

  @override
  String get membershipFreeBody =>
      'आप VIP सदस्य नहीं हैं। प्रीमियम एपिसोड अनलॉक करने के लिए कॉइन टॉप-अप करें।';

  @override
  String get membershipManageBody =>
      'सब्सक्रिप्शन का बिल और रद्दीकरण आपके ऐप स्टोर खाते से होता है।';

  @override
  String get manageSubscription => 'सब्सक्रिप्शन प्रबंधित करें';

  @override
  String get getCoins => 'कॉइन टॉप-अप';

  @override
  String get about => 'परिचय';

  @override
  String aboutVersion(String version, String build) {
    return 'संस्करण $version ($build)';
  }

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get licenses => 'ओपन-सोर्स लाइसेंस';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountSubtitle => 'अपना डेटा स्थायी रूप से हटाएँ';

  @override
  String get deleteWarning =>
      'यह वापस नहीं हो सकता। आपकी प्रोफ़ाइल, कॉइन, लाइब्रेरी, इतिहास और रेटिंग हट जाएँगी और आप साइन आउट हो जाएँगे।';

  @override
  String deleteTypeToConfirm(String word) {
    return 'पुष्टि के लिए $word टाइप करें';
  }

  @override
  String get deleteConfirm => 'Google से सत्यापित करें और हटाएँ';

  @override
  String get deleteFailed => 'खाता नहीं हटाया जा सका। कृपया फिर कोशिश करें।';

  @override
  String get savedOffline =>
      'इस डिवाइस पर सहेजा गया। ऑनलाइन होने पर सिंक होगा।';

  @override
  String clearCacheSize(String size) {
    return '$size उपयोग में';
  }
}
