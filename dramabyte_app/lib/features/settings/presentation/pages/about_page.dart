import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/config/app_config.dart';
import 'package:dramabyte_app/core/platform/external_link.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          children: [
            Center(child: FlareText(AppConfig.appName).xl4.bold),
            SizedBox(height: 6.h),
            Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (_, snapshot) {
                  final info = snapshot.data;
                  return FlareText(
                    info == null
                        ? ''
                        : l10n.aboutVersion(info.version, info.buildNumber),
                  ).sm.setColor(Theme.of(context).colorScheme.onSurfaceVariant);
                },
              ),
            ),
            SizedBox(height: 28.h),
            SettingsSection(
              title: l10n.about,
              children: [
                if (AppConfig.termsUrl.isNotEmpty)
                  SettingsTile(
                    icon: MdiIcons.fileDocumentOutline,
                    title: l10n.termsOfService,
                    onTap: () => openExternal(AppConfig.termsUrl),
                  ),
                if (AppConfig.privacyUrl.isNotEmpty)
                  SettingsTile(
                    icon: MdiIcons.shieldAccountOutline,
                    title: l10n.privacyPolicy,
                    onTap: () => openExternal(AppConfig.privacyUrl),
                  ),
                SettingsTile(
                  icon: MdiIcons.scaleBalance,
                  title: l10n.licenses,
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: AppConfig.appName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
