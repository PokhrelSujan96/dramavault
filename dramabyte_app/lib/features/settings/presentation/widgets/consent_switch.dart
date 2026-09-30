import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConsentSwitch extends StatelessWidget {
  const ConsentSwitch({
    super.key,
    required this.purpose,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ConsentPurpose purpose;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final granted = context.select(
      (ConsentCubit c) => c.state.preferences.isGranted(purpose),
    );
    return SettingsSwitchTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: granted,
      onChanged: (value) => context.read<ConsentCubit>().set(purpose, value),
    );
  }
}
