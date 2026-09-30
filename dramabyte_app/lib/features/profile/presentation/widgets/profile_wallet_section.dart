import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProfileWalletSection extends StatelessWidget {
  const ProfileWalletSection({super.key, required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
      child: Container(
        width: MediaQuery.of(context).size.width.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: context.surfaceTint,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FlareText('My Wallet').xl2.semiBold,
                Icon(MdiIcons.chevronRight),
              ],
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 0.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceStrong,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: FlareText('${profile.coins}').xl4,
                      ),
                      FlareText('Coins').grey.pt(5.h),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceStrong,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: FlareText('${profile.bonusCoins}').xl4,
                      ),
                      FlareText('Bonus').grey.pt(5.h),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 5.h,
                          horizontal: 12.w,
                        ),
                        decoration: BoxDecoration(
                          color: context.surfaceStrong,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: FlareText(
                          profile.vipDaysLeft == null
                              ? '--'
                              : '${profile.vipDaysLeft}D',
                        ).xl4,
                      ),
                      FlareText('Expire').grey.pt(5.h),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.pushNamed(AppRoutes.topupName),
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            vertical: 5.h,
                            horizontal: 12.w,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: FlareText('+').xl5,
                        ),
                        FlareText('Topup').grey.pt(5.h),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
