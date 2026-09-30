import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/core/theme/surface_colors.dart';
import 'package:dramabyte_app/features/referral/domain/entities/referral_summary.dart';
import 'package:dramabyte_app/features/referral/presentation/cubit/referral_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReferralPage extends StatelessWidget {
  const ReferralPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: FlareText('| Refer & Earn').xl, centerTitle: false),
      body: SafeArea(
        child: BlocBuilder<ReferralCubit, ResourceState<ReferralSummary>>(
          builder: (context, state) => switch (state) {
            ResourceLoaded<ReferralSummary>(:final value) => _Content(
              summary: value,
            ),
            ResourceError<ReferralSummary>(:final message) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FlareText(message).grey.center.pb(12.h),
                    FlareButton(
                      label: 'Try again',
                      expand: false,
                      onPressed: context.read<ReferralCubit>().retry,
                    ),
                  ],
                ),
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.summary});

  final ReferralSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.r),
      children: [
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: context.surfaceTint,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              FlareText('Your referral code').grey,
              SizedBox(height: 8.h),
              FlareText(summary.code).xl5.bold,
              SizedBox(height: 12.h),
              FlareButton(
                label: 'Copy code',
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: summary.code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied')),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        FlareText(
          'You and your friend both get ${summary.signupReward} coins when '
          'they sign up with your code, and ${summary.purchaseReward} more '
          'each when they make their first purchase.',
        ).grey,
        SizedBox(height: 20.h),
        Row(
          children: [
            _Stat(label: 'Invited', value: '${summary.invited}'),
            SizedBox(width: 8.w),
            _Stat(label: 'Purchased', value: '${summary.purchased}'),
            SizedBox(width: 8.w),
            _Stat(label: 'Earned', value: '${summary.earned}'),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.dividerDark,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Column(
          children: [FlareText(value).xl3, FlareText(label).grey.pt(4.h)],
        ),
      ),
    );
  }
}
