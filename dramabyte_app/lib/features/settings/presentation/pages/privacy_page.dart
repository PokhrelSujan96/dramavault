import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/settings/domain/entities/consent_preferences.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/consent_switch.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/offline_notice.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_switch_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyManagement)),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
              child: FlareText(
                l10n.privacyIntro,
              ).sm.setColor(Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            SettingsSection(
              title: l10n.sectionPrivacy,
              children: [
                SettingsSwitchTile(
                  icon: MdiIcons.lockOutline,
                  title: l10n.privacyEssential,
                  subtitle: l10n.privacyEssentialBody,
                  value: true,
                  onChanged: null,
                ),
                ConsentSwitch(
                  purpose: ConsentPurpose.analytics,
                  icon: MdiIcons.chartBoxOutline,
                  title: l10n.privacyAnalytics,
                  subtitle: l10n.privacyAnalyticsBody,
                ),
                ConsentSwitch(
                  purpose: ConsentPurpose.personalization,
                  icon: MdiIcons.autoFix,
                  title: l10n.privacyPersonalization,
                  subtitle: l10n.privacyPersonalizationBody,
                ),
              ],
            ),
            const OfflineNotice(),
          ],
        ),
      ),
    );
  }
}
