// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get settings => '설정';

  @override
  String get sectionPreferences => '환경설정';

  @override
  String get sectionPrivacy => '개인정보';

  @override
  String get sectionAccount => '계정';

  @override
  String get appearance => '화면 모드';

  @override
  String get appearanceSystem => '시스템 기본값';

  @override
  String get appearanceLight => '라이트';

  @override
  String get appearanceDark => '다크';

  @override
  String get language => '언어';

  @override
  String get languageSystem => '시스템 기본값';

  @override
  String get clearCache => '캐시 지우기';

  @override
  String get cacheCalculating => '계산 중…';

  @override
  String get clearCacheBody =>
      '다운로드한 에피소드와 저장된 이미지가 삭제됩니다. 계정과 보관함은 그대로 유지됩니다.';

  @override
  String get clearCacheDone => '캐시를 지웠습니다';

  @override
  String get cancel => '취소';

  @override
  String get clear => '지우기';

  @override
  String get marketing => '마케팅 정보 수신';

  @override
  String get marketingSubtitle => '혜택, 신규 시리즈 및 소식. 언제든 변경할 수 있습니다.';

  @override
  String get privacyManagement => '개인정보 관리';

  @override
  String get privacySubtitle => '쿠키 및 데이터 선택';

  @override
  String get privacyIntro =>
      'DramaByte가 쿠키 및 유사 기술을 사용하는 방식을 선택하세요. 언제든 변경할 수 있습니다.';

  @override
  String get privacyEssential => '필수';

  @override
  String get privacyEssentialBody => '로그인, 보안 및 재생. 항상 켜짐.';

  @override
  String get privacyAnalytics => '분석';

  @override
  String get privacyAnalyticsBody => '오류를 찾고 앱을 개선하는 데 도움이 됩니다.';

  @override
  String get privacyPersonalization => '맞춤 설정';

  @override
  String get privacyPersonalizationBody => '시청 기록을 바탕으로 시리즈를 추천합니다.';

  @override
  String get membership => '멤버십 관리';

  @override
  String membershipActive(int days) {
    return 'VIP · $days일 남음';
  }

  @override
  String get membershipFree => '무료 플랜';

  @override
  String get membershipFreeBody => 'VIP 회원이 아닙니다. 코인을 충전해 프리미엄 에피소드를 열어보세요.';

  @override
  String get membershipManageBody => '구독 결제와 해지는 앱 스토어 계정에서 진행됩니다.';

  @override
  String get manageSubscription => '구독 관리';

  @override
  String get getCoins => '코인 충전';

  @override
  String get about => '정보';

  @override
  String aboutVersion(String version, String build) {
    return '버전 $version ($build)';
  }

  @override
  String get termsOfService => '이용약관';

  @override
  String get privacyPolicy => '개인정보 처리방침';

  @override
  String get licenses => '오픈소스 라이선스';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get deleteAccountSubtitle => '내 데이터를 영구 삭제';

  @override
  String get deleteWarning =>
      '이 작업은 되돌릴 수 없습니다. 프로필, 코인, 보관함, 시청 기록, 평점이 삭제되고 로그아웃됩니다.';

  @override
  String deleteTypeToConfirm(String word) {
    return '확인하려면 $word를 입력하세요';
  }

  @override
  String get deleteConfirm => 'Google로 인증 후 삭제';

  @override
  String get deleteFailed => '계정을 삭제하지 못했습니다. 다시 시도해 주세요.';

  @override
  String get savedOffline => '이 기기에 저장했습니다. 온라인이 되면 동기화됩니다.';

  @override
  String clearCacheSize(String size) {
    return '$size 사용 중';
  }
}
