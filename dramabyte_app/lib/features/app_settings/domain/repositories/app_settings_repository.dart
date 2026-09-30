import 'package:flutter/material.dart';

abstract interface class AppSettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
  Future<String?> getLanguageCode();
  Future<void> saveLanguageCode(String? code);
}
