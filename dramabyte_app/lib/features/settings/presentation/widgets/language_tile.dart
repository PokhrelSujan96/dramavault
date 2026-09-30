import 'package:dramabyte_app/features/app_settings/presentation/cubit/app_settings_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:dramabyte_app/l10n/supported_languages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LanguageTile extends StatelessWidget {
  const LanguageTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final code = context.select(
      (AppSettingsCubit c) => c.state.locale?.languageCode,
    );
    final choices = <Choice<String?>>[
      (value: null, label: l10n.languageSystem),
      for (final language in SupportedLanguages.all)
        (value: language.code, label: language.nativeName),
    ];
    return SettingsTile(
      icon: MdiIcons.translate,
      title: l10n.language,
      value: choices.firstWhere((choice) => choice.value == code).label,
      onTap: () => showChoiceSheet<String?>(
        context,
        title: l10n.language,
        choices: choices,
        selected: code,
        onSelected: context.read<AppSettingsCubit>().setLanguage,
      ),
    );
  }
}
