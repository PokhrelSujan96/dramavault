import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/router/app_routes.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:dramabyte_app/features/profile/presentation/widgets/profile_builder.dart';
import 'package:dramabyte_app/features/profile/presentation/widgets/profile_details_bar.dart';
import 'package:dramabyte_app/features/profile/presentation/widgets/profile_history_section.dart';
import 'package:dramabyte_app/features/profile/presentation/widgets/profile_wallet_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FlareText('| Profile').xl,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(MdiIcons.cog),
            onPressed: () => context.pushNamed(AppRoutes.settingsName),
          ),
          SizedBox(width: 20.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(0),
          child: Divider(thickness: 0.2.h),
        ),
      ),
      body: ProfilePageView(),
    );
  }
}

class ProfilePageView extends StatelessWidget {
  const ProfilePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ProfileBuilder(
        builder: (context, profile) => ListView(
          padding: EdgeInsets.symmetric(vertical: 20.r),
          children: [
            ProfileDetailsBar(profile: profile),
            SizedBox(height: 24.h),
            ProfileHistorySection(),
            SizedBox(height: 20.h),
            ProfileWalletSection(profile: profile),
            SizedBox(height: 20.h),
            // ListTile(
            //   contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
            //   leading: Icon(MdiIcons.giftOutline),
            //   title: FlareText('Refer & Earn').xl,
            //   trailing: Icon(MdiIcons.chevronRight, color: Colors.grey),
            //   onTap: () => context.pushNamed(AppRoutes.referralName),
            // ),
            FlareTile(
              text: 'Refer & Earn',
              icon: MdiIcons.giftOutline,
              onTap: () => context.pushNamed(AppRoutes.referralName),
            ),
            SizedBox(height: 16.h),
            FlareTile(text: 'Your invoices', icon: MdiIcons.fileOutline),
            SizedBox(height: 16.h),
            FlareTile(
              text: 'Sign out',
              icon: MdiIcons.logout,
              onTap: () => context.read<AuthenticationBloc>().add(
                const SignOutRequested(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FlareTile extends StatelessWidget {
  const FlareTile({super.key, this.icon, required this.text, this.onTap});
  final IconData? icon;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: MediaQuery.of(context).size.width.w,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: context.surfaceTint,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [Icon(icon), FlareText(text).pl(12.w)]),
              Icon(MdiIcons.chevronRight, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
