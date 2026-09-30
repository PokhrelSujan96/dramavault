import 'package:dramabyte_app/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class AppSettingsRepositoryImpl implements AppSettingsRepository {
  AppSettingsRepositoryImpl(this._preferences);

  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language_code';
  final SharedPreferences _preferences;

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = _preferences.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) {
    return _preferences.setString(_themeModeKey, mode.name);
  }

  @override
  Future<String?> getLanguageCode() async =>
      _preferences.getString(_languageKey);

  @override
  Future<void> saveLanguageCode(String? code) async {
    if (code == null) {
      await _preferences.remove(_languageKey);
    } else {
      await _preferences.setString(_languageKey, code);
    }
  }
}
