import 'dart:io' show Platform;

import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/platform/external_link.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/features/profile/presentation/widgets/profile_builder.dart';
import 'package:dramabyte_app/features/settings/presentation/widgets/membership_status_card.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MembershipPage extends StatelessWidget {
  const MembershipPage({super.key});

  static String get _manageUrl => Platform.isIOS
      ? 'https://apps.apple.com/account/subscriptions'
      : 'https://play.google.com/store/account/subscriptions';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.membership)),
      body: SafeArea(
        child: ProfileBuilder(
          builder: (context, profile) => ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              MembershipStatusCard(profile: profile),
              SizedBox(height: 16.h),
              FlareText(
                l10n.membershipManageBody,
              ).sm.setColor(Theme.of(context).colorScheme.onSurfaceVariant),
              SizedBox(height: 20.h),
              FilledButton(
                onPressed: () => openExternal(_manageUrl),
                child: Text(l10n.manageSubscription),
              ),
              SizedBox(height: 10.h),
              OutlinedButton(
                onPressed: () => context.pushNamed(AppRoutes.topupName),
                child: Text(l10n.getCoins),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
