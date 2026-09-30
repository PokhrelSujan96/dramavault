import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/usecases/comment_use_cases.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comment_tree.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';

mixin CommentReplyLoading on Cubit<CommentsState> {
  ListReplies get listReplies;

  Future<void> toggleReplies(Comment comment) async {
    final current = state.repliesOf(comment.id);
    if (current.expanded) {
      return emit(withReplies(comment.id, current.copyWith(expanded: false)));
    }
    emit(withReplies(comment.id, current.copyWith(expanded: true)));
    if (!current.loaded) await loadReplies(comment.id);
  }

  Future<void> loadReplies(String commentId) async {
    final current = state.repliesOf(commentId);
    if (current.loading) return;
    emit(
      withReplies(commentId, current.copyWith(loading: true, expanded: true)),
    );
    try {
      final page = await listReplies(
        ListRepliesParams(
          commentId,
          current.loaded ? current.nextCursor : null,
        ),
      );
      if (isClosed) return;
      final latest = state.repliesOf(commentId);
      final merged = current.loaded
          ? state.mergeUnique(latest.items, page.items)
          : [
              ...page.items,
              for (final own in latest.items)
                if (!page.items.any((c) => c.id == own.id)) own,
            ];
      emit(
        withReplies(
          commentId,
          latest.copyWith(
            items: merged,
            nextCursor: page.nextCursor,
            clearCursor: page.nextCursor == null,
            loading: false,
            loaded: true,
          ),
        ),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        withReplies(
          commentId,
          state.repliesOf(commentId).copyWith(loading: false),
        ).copyWith(notice: failure.message),
      );
    }
  }

  CommentsState withReplies(String id, RepliesState replies) =>
      state.copyWith(replies: {...state.replies, id: replies});
}
