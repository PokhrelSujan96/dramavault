import 'package:dramabyte_app/components/flare_text.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CommentReplies extends StatelessWidget {
  const CommentReplies({
    super.key,
    required this.parent,
    required this.replies,
    required this.onToggle,
    required this.onLoadMore,
    required this.onReply,
    required this.onLike,
    required this.onLongPress,
  });

  final Comment parent;
  final RepliesState replies;
  final VoidCallback onToggle;
  final VoidCallback onLoadMore;
  final ValueChanged<Comment> onReply;
  final ValueChanged<Comment> onLike;
  final ValueChanged<Comment> onLongPress;

  bool get _hasMore =>
      parent.replyCount > replies.items.length &&
      (!replies.loaded || replies.nextCursor != null);

  @override
  Widget build(BuildContext context) {
    if (parent.replyCount == 0 && replies.items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(left: 48.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (replies.expanded)
            for (final reply in replies.items)
              CommentTile(
                key: ValueKey(reply.id),
                comment: reply,
                onReply: () => onReply(reply),
                onLike: () => onLike(reply),
                onLongPress: () => onLongPress(reply),
              ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: Wrap(
              spacing: 16.w,
              children: [
                if (!replies.expanded)
                  _Link(
                    'View ${parent.replyCount} ${parent.replyCount == 1 ? 'reply' : 'replies'}',
                    onToggle,
                  )
                else ...[
                  if (replies.loading)
                    SizedBox.square(
                      dimension: 14.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_hasMore)
                    _Link(
                      'View ${parent.replyCount - replies.items.length} more',
                      onLoadMore,
                    ),
                  _Link('Hide', onToggle),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Link extends StatelessWidget {
  const _Link(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: FlareText(label).xs.grey.semiBold,
  );
}
