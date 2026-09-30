import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/features/profile/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileDetailsBar extends StatelessWidget {
  const ProfileDetailsBar({super.key, required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Container(
            height: 50.h,
            width: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: FlareColors.dislikeActive,
              image: profile.avatarUrl == null
                  ? null
                  : DecorationImage(
                      image: NetworkImage(profile.avatarUrl!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: profile.avatarUrl == null
                ? Center(child: FlareText(profile.initial))
                : null,
          ),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlareText(profile.name).xl,
              if (profile.email != null) FlareText(profile.email!).grey,
            ],
          ),
        ],
      ),
    );
  }
}
