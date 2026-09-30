import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/format/uuid.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:dramabyte_app/features/comments/domain/usecases/comment_use_cases.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comment_like_sync.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comment_reply_loading.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comment_tree.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_args.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';

class CommentsCubit extends Cubit<CommentsState> with CommentReplyLoading {
  CommentsCubit(
    this.args,
    this._list,
    this._replies,
    this._post,
    this._setLike,
    this._delete,
    this._report, {
    required this.onCountChanged,
    this.likeDelay = const Duration(milliseconds: 350),
  }) : super(const CommentsState());

  final CommentsArgs args;
  final ListComments _list;
  final ListReplies _replies;

  @override
  ListReplies get listReplies => _replies;

  final PostComment _post;
  final SetCommentLike _setLike;
  final DeleteComment _delete;
  final ReportComment _report;
  final void Function(int delta) onCountChanged;
  final Duration likeDelay;
  final _retryKeys = <String, String>{};
  late final _likes = CommentLikeSync(
    _setLike,
    delay: likeDelay,
    currentLiked: (id) => state.find(id)?.liked,
    onRevert: _revertLike,
  );

  Future<void> load() async {
    emit(CommentsState(sort: state.sort));
    try {
      final page = await _list(ListCommentsParams(args.episodeId, state.sort));
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CommentsStatus.ready,
          items: page.items,
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
        ),
      );
    } on Failure catch (failure) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: CommentsStatus.failure,
            error: failure.message,
          ),
        );
      }
    }
  }

  Future<void> setSort(CommentSort sort) {
    if (sort == state.sort) return Future.value();
    emit(CommentsState(sort: sort));
    return load();
  }

  Future<void> loadMore() async {
    if (state.nextCursor == null ||
        state.loadingMore ||
        state.status != CommentsStatus.ready) {
      return;
    }
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _list(
        ListCommentsParams(args.episodeId, state.sort, state.nextCursor),
      );
      if (isClosed) return;
      emit(
        state.copyWith(
          items: state.mergeUnique(state.items, page.items),
          nextCursor: page.nextCursor,
          clearCursor: page.nextCursor == null,
          loadingMore: false,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(loadingMore: false));
    }
  }

  void startReply(Comment comment) {
    if (!comment.pending) emit(state.copyWith(replyTo: comment));
  }

  void cancelReply() => emit(state.copyWith(clearReply: true));

  Future<String?> post(String raw) async {
    final body = raw.trim();
    if (body.isEmpty) return null;
    final target = state.replyTo;
    final topId = target == null ? null : (target.parentId ?? target.id);
    final retryId = '${target?.id ?? ''}|$body';
    final key = _retryKeys.putIfAbsent(retryId, generateUuidV4);
    final temp = Comment(
      id: 'temp:$key',
      episodeId: args.episodeId,
      body: body,
      authorId: args.authorId,
      parentId: topId,
      createdAt: DateTime.now(),
      authorName: args.authorName,
      authorAvatar: args.authorAvatar,
      isMine: true,
      pending: true,
    );
    emit(state.addLocal(temp).copyWith(clearReply: true));
    onCountChanged(1);
    try {
      final saved = await _post(
        PostCommentParams(
          episodeId: args.episodeId,
          body: body,
          key: key,
          parentId: target?.id,
        ),
      );
      _retryKeys.remove(retryId);
      if (!isClosed) emit(state.replaceLocal(temp.id, saved));
      return null;
    } on Failure catch (failure) {
      if (!isClosed) emit(state.removeLocal(temp));
      onCountChanged(-1);
      return failure.message;
    }
  }

  void toggleLike(Comment comment) {
    if (comment.pending) return;
    final current = state.find(comment.id) ?? comment;
    _likes.schedule(comment.id, before: current.liked);
    emit(state.mutate(comment.id, (c) => _flipLike(c, liked: !c.liked)));
  }

  Future<void> delete(Comment comment) async {
    if (comment.pending || !comment.isMine) return;
    final before = state;
    final removed = comment.isReply ? 1 : 1 + comment.replyCount;
    emit(state.removeLocal(comment));
    onCountChanged(-removed);
    try {
      await _delete(comment.id);
    } on Failure catch (failure) {
      onCountChanged(removed);
      if (!isClosed) emit(before.copyWith(notice: failure.message));
    }
  }

  Future<void> report(Comment comment, String reason) async {
    try {
      await _report(ReportCommentParams(comment.id, reason));
      emit(state.copyWith(notice: 'Thanks for letting us know.'));
    } on Failure catch (failure) {
      emit(state.copyWith(notice: failure.message));
    }
  }

  void _revertLike(String id, bool liked, String message) {
    if (isClosed) return;
    emit(
      state
          .mutate(id, (c) => _flipLike(c, liked: liked))
          .copyWith(notice: message),
    );
  }

  Comment _flipLike(Comment comment, {required bool liked}) {
    if (comment.liked == liked) return comment;
    final delta = liked ? 1 : -1;
    return comment.copyWith(
      liked: liked,
      likeCount: (comment.likeCount + delta).clamp(0, 1 << 31),
    );
  }

  @override
  Future<void> close() {
    _likes.dispose();
    return super.close();
  }
}
