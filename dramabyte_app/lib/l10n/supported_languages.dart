import 'dart:ui';

final class SupportedLanguage {
  const SupportedLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  Locale get locale => Locale(code);
}

abstract final class SupportedLanguages {
  static const all = [
    SupportedLanguage('en', 'English'),
    SupportedLanguage('ja', '日本語'),
    SupportedLanguage('zh', '中文'),
    SupportedLanguage('es', 'Español'),
    SupportedLanguage('hi', 'हिन्दी'),
    SupportedLanguage('ne', 'नेपाली'),
    SupportedLanguage('pl', 'Polski'),
    SupportedLanguage('ko', '한국어'),
  ];

  static List<Locale> get locales => [for (final l in all) l.locale];

  static Locale? resolve(String? code) {
    for (final language in all) {
      if (language.code == code) return language.locale;
    }
    return null;
  }
}
