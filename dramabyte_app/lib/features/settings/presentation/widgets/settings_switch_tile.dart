import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      secondary: Icon(icon),
      title: FlareText(title).base.medium,
      subtitle: FlareText(subtitle).sm.setColor(scheme.onSurfaceVariant),
    );
  }
}
