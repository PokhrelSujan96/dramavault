import 'package:dramabyte_app/components/flare_svg_icon.dart';
import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_sheet.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/presentation/widgets/reel_action_button.dart';
import 'package:dramabyte_app/features/engagement/presentation/cubit/engagement_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReelCommentButton extends StatelessWidget {
  const ReelCommentButton({super.key, required this.reel});

  final Reel reel;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<EngagementCubit, EngagementState, int?>(
      selector: (state) => state.episodes[reel.episodeId]?.comments,
      builder: (context, comments) => ReelActionButton(
        icon: FlareSvgIcon('comment', size: 23.sp, color: Colors.white),
        label: compactCount(comments ?? reel.comments),
        onTap: () => showCommentsSheet(context, reel),
      ),
    );
  }
}
