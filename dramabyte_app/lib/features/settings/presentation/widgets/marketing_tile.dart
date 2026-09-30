import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MarketingTile extends StatelessWidget {
  const MarketingTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final granted = context.select(
      (ConsentCubit c) => c.state.preferences.marketing,
    );
    return SettingsSwitchTile(
      icon: MdiIcons.emailOutline,
      title: l10n.marketing,
      subtitle: l10n.marketingSubtitle,
      value: granted,
      onChanged: (value) =>
          context.read<ConsentCubit>().set(ConsentPurpose.marketing, value),
    );
  }
}
