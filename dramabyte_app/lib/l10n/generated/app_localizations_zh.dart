// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get settings => '设置';

  @override
  String get sectionPreferences => '偏好设置';

  @override
  String get sectionPrivacy => '隐私';

  @override
  String get sectionAccount => '账户';

  @override
  String get appearance => '外观';

  @override
  String get appearanceSystem => '跟随系统';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceDark => '深色';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get clearCache => '清除缓存';

  @override
  String get cacheCalculating => '计算中…';

  @override
  String get clearCacheBody => '已下载的剧集和缓存的图片将被删除，您的账户和收藏不受影响。';

  @override
  String get clearCacheDone => '缓存已清除';

  @override
  String get cancel => '取消';

  @override
  String get clear => '清除';

  @override
  String get marketing => '接收营销信息';

  @override
  String get marketingSubtitle => '优惠、新剧集和动态。可随时更改。';

  @override
  String get privacyManagement => '隐私管理';

  @override
  String get privacySubtitle => 'Cookie 与数据选项';

  @override
  String get privacyIntro => '选择 DramaByte 如何使用 Cookie 及类似技术，可随时更改。';

  @override
  String get privacyEssential => '必要';

  @override
  String get privacyEssentialBody => '登录、安全和播放所需，始终开启。';

  @override
  String get privacyAnalytics => '数据分析';

  @override
  String get privacyAnalyticsBody => '帮助我们发现问题并改进应用。';

  @override
  String get privacyPersonalization => '个性化';

  @override
  String get privacyPersonalizationBody => '根据您的观看内容推荐剧集。';

  @override
  String get membership => '管理会员';

  @override
  String membershipActive(int days) {
    return 'VIP · 剩余 $days 天';
  }

  @override
  String get membershipFree => '免费版';

  @override
  String get membershipFreeBody => '您还不是 VIP 会员。充值金币即可解锁付费剧集。';

  @override
  String get membershipManageBody => '订阅的扣费与取消均通过您的应用商店账户办理。';

  @override
  String get manageSubscription => '管理订阅';

  @override
  String get getCoins => '充值金币';

  @override
  String get about => '关于';

  @override
  String aboutVersion(String version, String build) {
    return '版本 $version（$build）';
  }

  @override
  String get termsOfService => '服务条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get licenses => '开源许可';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountSubtitle => '永久删除您的数据';

  @override
  String get deleteWarning => '此操作无法撤销。您的资料、金币、收藏、历史和评分将被删除，并退出登录。';

  @override
  String deleteTypeToConfirm(String word) {
    return '请输入 $word 以确认';
  }

  @override
  String get deleteConfirm => '通过 Google 验证并删除';

  @override
  String get deleteFailed => '无法删除账户，请重试。';

  @override
  String get savedOffline => '已保存在本设备，联网后将自动同步。';

  @override
  String clearCacheSize(String size) {
    return '已用 $size';
  }
}
