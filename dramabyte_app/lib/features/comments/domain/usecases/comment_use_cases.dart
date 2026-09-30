import 'package:dramabyte_app/core/usecases/use_case.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:dramabyte_app/features/comments/domain/repositories/comment_repository.dart';

final class ListCommentsParams {
  const ListCommentsParams(this.episodeId, this.sort, [this.cursor]);

  final String episodeId;
  final CommentSort sort;
  final String? cursor;
}

final class ListComments implements UseCase<CommentPage, ListCommentsParams> {
  ListComments(this._repository);

  final CommentRepository _repository;

  @override
  Future<CommentPage> call(ListCommentsParams params) => _repository.list(
    params.episodeId,
    sort: params.sort,
    cursor: params.cursor,
  );
}

final class ListRepliesParams {
  const ListRepliesParams(this.commentId, [this.cursor]);

  final String commentId;
  final String? cursor;
}

final class ListReplies implements UseCase<CommentPage, ListRepliesParams> {
  ListReplies(this._repository);

  final CommentRepository _repository;

  @override
  Future<CommentPage> call(ListRepliesParams params) =>
      _repository.replies(params.commentId, cursor: params.cursor);
}

final class PostCommentParams {
  const PostCommentParams({
    required this.episodeId,
    required this.body,
    required this.key,
    this.parentId,
  });

  final String episodeId;
  final String body;
  final String key;
  final String? parentId;
}

final class PostComment implements UseCase<Comment, PostCommentParams> {
  PostComment(this._repository);

  final CommentRepository _repository;

  @override
  Future<Comment> call(PostCommentParams params) => _repository.post(
    episodeId: params.episodeId,
    body: params.body,
    key: params.key,
    parentId: params.parentId,
  );
}

final class SetCommentLikeParams {
  const SetCommentLikeParams(this.commentId, {required this.liked});

  final String commentId;
  final bool liked;
}

final class SetCommentLike implements UseCase<void, SetCommentLikeParams> {
  SetCommentLike(this._repository);

  final CommentRepository _repository;

  @override
  Future<void> call(SetCommentLikeParams params) =>
      _repository.setLike(params.commentId, liked: params.liked);
}

final class DeleteComment implements UseCase<void, String> {
  DeleteComment(this._repository);

  final CommentRepository _repository;

  @override
  Future<void> call(String params) => _repository.delete(params);
}

final class ReportCommentParams {
  const ReportCommentParams(this.commentId, this.reason);

  final String commentId;
  final String reason;
}

final class ReportComment implements UseCase<void, ReportCommentParams> {
  ReportComment(this._repository);

  final CommentRepository _repository;

  @override
  Future<void> call(ReportCommentParams params) =>
      _repository.report(params.commentId, params.reason);
}
