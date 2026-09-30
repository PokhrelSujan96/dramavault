import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/cache_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/cubit/consent_cubit.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/appearance_tile.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/cache_tile.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/language_tile.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/marketing_tile.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/offline_notice.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_section.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/settings_tile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ConsentCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocProvider(
      create: (_) => getIt<CacheCubit>()..measure(),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            children: [
              SettingsSection(
                title: l10n.sectionPreferences,
                children: const [AppearanceTile(), LanguageTile(), CacheTile()],
              ),
              SettingsSection(
                title: l10n.sectionPrivacy,
                children: [
                  const MarketingTile(),
                  SettingsTile(
                    icon: MdiIcons.shieldLockOutline,
                    title: l10n.privacyManagement,
                    subtitle: l10n.privacySubtitle,
                    onTap: () => context.pushNamed(AppRoutes.privacyName),
                  ),
                ],
              ),
              const OfflineNotice(),
              SettingsSection(
                title: l10n.sectionAccount,
                children: [
                  SettingsTile(
                    icon: MdiIcons.crownOutline,
                    title: l10n.membership,
                    onTap: () => context.pushNamed(AppRoutes.membershipName),
                  ),
                  SettingsTile(
                    icon: MdiIcons.informationOutline,
                    title: l10n.about,
                    onTap: () => context.pushNamed(AppRoutes.aboutName),
                  ),
                  SettingsTile(
                    icon: MdiIcons.accountRemoveOutline,
                    title: l10n.deleteAccount,
                    subtitle: l10n.deleteAccountSubtitle,
                    destructive: true,
                    onTap: () => context.pushNamed(AppRoutes.deleteAccountName),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
