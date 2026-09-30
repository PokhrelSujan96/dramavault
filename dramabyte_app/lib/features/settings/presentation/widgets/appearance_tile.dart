import 'package:dramabyte_app/features/app_settings/presentation/cubit/app_settings_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/choice_sheet.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class AppearanceTile extends StatelessWidget {
  const AppearanceTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mode = context.select((AppSettingsCubit c) => c.state.themeMode);
    final choices = <Choice<ThemeMode>>[
      (value: ThemeMode.system, label: l10n.appearanceSystem),
      (value: ThemeMode.light, label: l10n.appearanceLight),
      (value: ThemeMode.dark, label: l10n.appearanceDark),
    ];
    return SettingsTile(
      icon: MdiIcons.themeLightDark,
      title: l10n.appearance,
      value: choices.firstWhere((choice) => choice.value == mode).label,
      onTap: () => showChoiceSheet(
        context,
        title: l10n.appearance,
        choices: choices,
        selected: mode,
        onSelected: context.read<AppSettingsCubit>().setThemeMode,
      ),
    );
  }
}
