import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_button.dart';
import 'package:dramabyte_app/features/engagement/domain/entities/episode_engagement.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ReelLikeButton extends StatelessWidget {
  const ReelLikeButton({super.key, required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EngagementCubit, EngagementState, EpisodeEngagement?>(
      selector: (state) => state.episodes[reel.episodeId],
      builder: (context, engagement) {
        final liked = engagement?.liked ?? reel.liked;
        final likes = engagement?.likes ?? reel.likes;
        return ReelActionButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.elasticOut,
              ),
              child: child,
            ),
            child: liked
                ? FlareSvgIcon(
                    'heart',
                    key: const ValueKey(true),
                    size: 30.sp,
                    color: FlareColors.primary,
                  )
                : Icon(
                    MdiIcons.heartOutline,
                    key: const ValueKey(false),
                    size: 30.sp,
                    color: Colors.white,
                  ),
          ),
          label: compactCount(likes),
          onTap: () =>
              context.read<EngagementCubit>().toggleLike(reel.episodeId),
        );
      },
    );
  }
}
