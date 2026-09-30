import 'package:dramabyte_app/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:dramabyte_app/features/app_settings/presentation/cubit/app_settings_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads the stored theme mode', () async {
    final repository = _FakeAppSettingsRepository(ThemeMode.dark);
    final cubit = AppSettingsCubit(repository);

    await cubit.load();

    expect(cubit.state.themeMode, ThemeMode.dark);
    await cubit.close();
  });

  test('applies and stores the chosen language', () async {
    final repository = _FakeAppSettingsRepository(ThemeMode.system);
    final cubit = AppSettingsCubit(repository);

    await cubit.setLanguage('ja');
    expect(cubit.state.locale, const Locale('ja'));
    expect(repository.code, 'ja');

    await cubit.setLanguage(null);
    expect(cubit.state.locale, isNull);
    await cubit.close();
  });
}

final class _FakeAppSettingsRepository implements AppSettingsRepository {
  _FakeAppSettingsRepository(this.mode);

  ThemeMode mode;
  String? code;

  @override
  Future<ThemeMode> getThemeMode() async => mode;

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    this.mode = mode;
  }

  @override
  Future<String?> getLanguageCode() async => code;

  @override
  Future<void> saveLanguageCode(String? code) async {
    this.code = code;
  }
}
