import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/constants/app_colors.dart';
import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CommentLikeButton extends StatelessWidget {
  const CommentLikeButton({
    super.key,
    required this.comment,
    required this.onTap,
  });

  final Comment comment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: comment.pending ? null : onTap,
      child: SizedBox(
        width: 40.w,
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.elasticOut,
                ),
                child: child,
              ),
              child: Icon(
                comment.liked ? MdiIcons.heart : MdiIcons.heartOutline,
                key: ValueKey(comment.liked),
                size: 20.sp,
                color: comment.liked ? FlareColors.primary : Colors.grey,
              ),
            ),
            SizedBox(height: 2.h),
            FlareText(
              comment.likeCount > 0 ? compactCount(comment.likeCount) : '',
            ).xs.grey,
          ],
        ),
      ),
    );
  }
}
