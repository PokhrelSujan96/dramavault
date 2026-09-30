import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'dart:async';

import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/di/injection.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/coin_packages_cubit.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TopupPage extends StatelessWidget {
  const TopupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TopupCubit>(),
      child: BlocListener<TopupCubit, TopupState>(
        listenWhen: (previous, state) =>
            state.noticeSeq != previous.noticeSeq && state.notice != null,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.notice!)));
          final credited = state.credited;
          if (credited == null) return;
          final profile = context.read<ProfileCubit>()
            ..update(
              (current) => current.copyWith(
                coins: current.coins + credited.coins,
                bonusCoins: current.bonusCoins + credited.bonusCoins,
              ),
            );
          unawaited(profile.refresh());
        },
        child: Scaffold(
          appBar: AppBar(
            title: FlareText('profile | topup').xl,
            automaticallyImplyLeading: false,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: Icon(MdiIcons.chevronLeft),
            ),
            centerTitle: false,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(0),
              child: Divider(thickness: 0.2.h),
            ),
          ),
          body: const SafeArea(child: _TopupView()),
        ),
      ),
    );
  }
}

class _TopupView extends StatelessWidget {
  const _TopupView();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CoinPackagesCubit>().state;
    final purchasingId = context.select(
      (TopupCubit cubit) => cubit.state.purchasingId,
    );
    return switch (state) {
      ResourceLoaded<List<CoinPackage>>(:final value) => ListView.separated(
        padding: EdgeInsets.all(16.r),
        itemCount: value.length,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (context, index) =>
            _PackageTile(package: value[index], purchasingId: purchasingId),
      ),
      ResourceError<List<CoinPackage>>(:final message) => Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlareText(message).grey.center.pb(12.h),
              FlareButton(
                label: 'Try again',
                expand: false,
                onPressed: context.read<CoinPackagesCubit>().retry,
              ),
            ],
          ),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({required this.package, required this.purchasingId});

  final CoinPackage package;
  final String? purchasingId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.surfaceTint,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FlareText('${package.coins}').xl3.bold,
                FlareText('Coins').grey,
                if (package.bonusCoins > 0)
                  Container(
                    margin: EdgeInsets.only(top: 6.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: FlareText('+${package.bonusCoins} bonus').sm,
                  ),
              ],
            ),
          ),
          FlareButton(
            label: package.priceLabel,
            expand: false,
            isLoading: purchasingId == package.id,
            onPressed: purchasingId == null
                ? () => context.read<TopupCubit>().purchase(package)
                : null,
          ),
        ],
      ),
    );
  }
}
