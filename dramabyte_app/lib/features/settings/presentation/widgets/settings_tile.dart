import 'package:dramabyte_app/components/flare_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.value,
    this.destructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? value;
  final bool destructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.onSurface;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
      leading: Icon(icon, color: color),
      title: FlareText(title).base.medium.setColor(color),
      subtitle: subtitle == null
          ? null
          : FlareText(subtitle!).sm.setColor(scheme.onSurfaceVariant),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            FlareText(value!).sm.setColor(scheme.onSurfaceVariant),
          if (onTap != null)
            Icon(MdiIcons.chevronRight, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
