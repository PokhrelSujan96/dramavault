// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get settings => '設定';

  @override
  String get sectionPreferences => '環境設定';

  @override
  String get sectionPrivacy => 'プライバシー';

  @override
  String get sectionAccount => 'アカウント';

  @override
  String get appearance => '外観';

  @override
  String get appearanceSystem => 'システム設定に従う';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get languageSystem => 'システム設定に従う';

  @override
  String get clearCache => 'キャッシュを削除';

  @override
  String get cacheCalculating => '計算中…';

  @override
  String get clearCacheBody =>
      'ダウンロードしたエピソードと保存済みの画像が削除されます。アカウントとライブラリは影響を受けません。';

  @override
  String get clearCacheDone => 'キャッシュを削除しました';

  @override
  String get cancel => 'キャンセル';

  @override
  String get clear => '削除';

  @override
  String get marketing => 'マーケティング情報の受信';

  @override
  String get marketingSubtitle => '特典や新シリーズのお知らせ。いつでも変更できます。';

  @override
  String get privacyManagement => 'プライバシー管理';

  @override
  String get privacySubtitle => 'Cookieとデータの選択';

  @override
  String get privacyIntro => 'DramaByteによるCookieなどの利用方法を選択できます。いつでも変更可能です。';

  @override
  String get privacyEssential => '必須';

  @override
  String get privacyEssentialBody => 'ログイン、セキュリティ、再生に必要です。常に有効です。';

  @override
  String get privacyAnalytics => '分析';

  @override
  String get privacyAnalyticsBody => '不具合の発見とアプリの改善に役立ちます。';

  @override
  String get privacyPersonalization => 'パーソナライズ';

  @override
  String get privacyPersonalizationBody => '視聴履歴に基づいておすすめを表示します。';

  @override
  String get membership => 'メンバーシップの管理';

  @override
  String membershipActive(int days) {
    return 'VIP・残り$days日';
  }

  @override
  String get membershipFree => '無料プラン';

  @override
  String get membershipFreeBody => '現在VIPではありません。コインチャージでプレミアムエピソードを解放できます。';

  @override
  String get membershipManageBody => 'サブスクリプションの請求と解約はアプリストアのアカウントで行います。';

  @override
  String get manageSubscription => 'サブスクリプションを管理';

  @override
  String get getCoins => 'コインをチャージ';

  @override
  String get about => 'このアプリについて';

  @override
  String aboutVersion(String version, String build) {
    return 'バージョン $version（$build）';
  }

  @override
  String get termsOfService => '利用規約';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get licenses => 'オープンソースライセンス';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get deleteAccountSubtitle => 'データを完全に削除します';

  @override
  String get deleteWarning =>
      'この操作は取り消せません。プロフィール、コイン、ライブラリ、履歴、評価が削除され、ログアウトされます。';

  @override
  String deleteTypeToConfirm(String word) {
    return '確認のため $word と入力してください';
  }

  @override
  String get deleteConfirm => 'Googleで確認して削除';

  @override
  String get deleteFailed => 'アカウントを削除できませんでした。もう一度お試しください。';

  @override
  String get savedOffline => 'この端末に保存しました。オンラインに戻ったら同期します。';

  @override
  String clearCacheSize(String size) {
    return '$size 使用中';
  }
}
