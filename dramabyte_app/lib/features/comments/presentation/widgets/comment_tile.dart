import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/core/format/time_ago.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_avatar.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_like_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    super.key,
    required this.comment,
    required this.onReply,
    required this.onLike,
    required this.onLongPress,
  });

  final Comment comment;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: comment.pending ? null : onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: comment.pending ? 0.5 : 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommentAvatar(
                name: comment.authorName,
                url: comment.authorAvatar,
                size: comment.isReply ? 28.w : 36.w,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlareText(comment.authorName).sm.grey.semiBold,
                    SizedBox(height: 2.h),
                    FlareText(comment.body).base,
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        FlareText(
                          comment.pending
                              ? 'Posting…'
                              : timeAgo(comment.createdAt),
                        ).xs.grey,
                        SizedBox(width: 16.w),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: comment.pending ? null : onReply,
                          child: FlareText('Reply').xs.grey.semiBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              CommentLikeButton(comment: comment, onTap: onLike),
            ],
          ),
        ),
      ),
    );
  }
}
