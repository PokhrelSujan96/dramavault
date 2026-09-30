import 'package:dramabyte_app/components/flare_button.dart';
import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/sync/synced_cubit.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:dramabyte_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ProfileContext on BuildContext {
  UserProfile? get profile {
    final state = watch<ProfileCubit>().state;
    return state is ResourceLoaded<UserProfile> ? state.value : null;
  }
}

class ProfileBuilder extends StatelessWidget {
  const ProfileBuilder({required this.builder, this.placeholder, super.key});

  final Widget Function(BuildContext context, UserProfile profile) builder;
  final WidgetBuilder? placeholder;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ResourceState<UserProfile>>(
      builder: (context, state) => switch (state) {
        ResourceLoaded<UserProfile>(:final value) => builder(context, value),
        ResourceError<UserProfile>(:final message) => Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlareText(message).grey.center.pb(12.h),
                FlareButton(
                  label: 'Try again',
                  expand: false,
                  onPressed: context.read<ProfileCubit>().retry,
                ),
              ],
            ),
          ),
        ),
        _ =>
          placeholder?.call(context) ??
              const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
