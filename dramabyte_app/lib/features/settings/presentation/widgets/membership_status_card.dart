import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class MembershipStatusCard extends StatelessWidget {
  const MembershipStatusCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final vip = profile.isVip;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: vip
            ? scheme.primary.withValues(alpha: 0.14)
            : scheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Icon(
            vip ? MdiIcons.crown : MdiIcons.crownOutline,
            size: 32.r,
            color: vip ? scheme.primary : scheme.onSurfaceVariant,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlareText(
                  vip
                      ? l10n.membershipActive(profile.vipDaysLeft ?? 0)
                      : l10n.membershipFree,
                ).lg.semiBold,
                if (!vip) ...[
                  SizedBox(height: 4.h),
                  FlareText(
                    l10n.membershipFreeBody,
                  ).sm.setColor(scheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
