import 'package:dramabyte_app/features/comments/presentation/cubit/comments_cubit.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_actions_sheet.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_replies.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comment_tile.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_empty_view.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_error_view.dart';
import 'package:dramabyte_app/features/comments/presentation/widgets/comments_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommentList extends StatefulWidget {
  const CommentList({super.key});

  @override
  State<CommentList> createState() => _CommentListState();
}

class _CommentListState extends State<CommentList> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.hasClients && _controller.position.extentAfter < 320) {
        context.read<CommentsCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CommentsCubit>();
    return BlocBuilder<CommentsCubit, CommentsState>(
      builder: (context, state) => switch (state.status) {
        CommentsStatus.loading => const CommentsSkeleton(),
        CommentsStatus.failure => CommentsErrorView(
          message: state.error ?? 'Could not load comments.',
          onRetry: cubit.load,
        ),
        CommentsStatus.ready when state.items.isEmpty =>
          const CommentsEmptyView(),
        CommentsStatus.ready => ListView.builder(
          controller: _controller,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: state.items.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
            final comment = state.items[index];
            return Column(
              key: ValueKey(comment.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CommentTile(
                  comment: comment,
                  onReply: () => cubit.startReply(comment),
                  onLike: () => cubit.toggleLike(comment),
                  onLongPress: () =>
                      showCommentActions(context, comment, cubit),
                ),
                CommentReplies(
                  parent: comment,
                  replies: state.repliesOf(comment.id),
                  onToggle: () => cubit.toggleReplies(comment),
                  onLoadMore: () => cubit.loadReplies(comment.id),
                  onReply: cubit.startReply,
                  onLike: cubit.toggleLike,
                  onLongPress: (reply) =>
                      showCommentActions(context, reply, cubit),
                ),
              ],
            );
          },
        ),
      },
    );
  }
}
