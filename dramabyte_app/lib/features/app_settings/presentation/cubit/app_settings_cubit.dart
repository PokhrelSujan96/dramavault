import 'package:dramabyte_app/features/app_settings/domain/repositories/app_settings_repository.dart';
import 'package:dramabyte_app/l10n/supported_languages.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class AppSettingsState extends Equatable {
  const AppSettingsState({this.themeMode = ThemeMode.system, this.locale});

  final ThemeMode themeMode;
  final Locale? locale;

  AppSettingsState copyWith({ThemeMode? themeMode}) {
    return AppSettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale,
    );
  }

  AppSettingsState withLocale(Locale? locale) {
    return AppSettingsState(themeMode: themeMode, locale: locale);
  }

  @override
  List<Object?> get props => [themeMode, locale];
}

final class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._repository) : super(const AppSettingsState());

  final AppSettingsRepository _repository;

  Future<void> load() async {
    final mode = await _repository.getThemeMode();
    final code = await _repository.getLanguageCode();
    emit(
      AppSettingsState(
        themeMode: mode,
        locale: SupportedLanguages.resolve(code),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(state.copyWith(themeMode: mode));
    await _repository.saveThemeMode(mode);
  }

  Future<void> setLanguage(String? code) async {
    emit(state.withLocale(SupportedLanguages.resolve(code)));
    await _repository.saveLanguageCode(code);
  }
}
