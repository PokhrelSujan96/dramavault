import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';

abstract interface class CommentRepository {
  Future<CommentPage> list(
    String episodeId, {
    required CommentSort sort,
    String? cursor,
  });
  Future<CommentPage> replies(String commentId, {String? cursor});
  Future<Comment> post({
    required String episodeId,
    required String body,
    required String key,
    String? parentId,
  });
  Future<void> setLike(String commentId, {required bool liked});
  Future<void> delete(String commentId);
  Future<void> report(String commentId, String reason);
}
