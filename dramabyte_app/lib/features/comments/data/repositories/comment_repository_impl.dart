import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/features/comments/data/datasources/comment_remote_source.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:dramabyte_app/features/comments/domain/repositories/comment_repository.dart';

final class CommentRepositoryImpl implements CommentRepository {
  CommentRepositoryImpl(this._remote);

  final CommentRemoteSource _remote;

  @override
  Future<CommentPage> list(
    String episodeId, {
    required CommentSort sort,
    String? cursor,
  }) => _guard(
    () async => (await _remote.list(episodeId, sort, cursor)).toEntity(),
  );

  @override
  Future<CommentPage> replies(String commentId, {String? cursor}) =>
      _guard(() async => (await _remote.replies(commentId, cursor)).toEntity());

  @override
  Future<Comment> post({
    required String episodeId,
    required String body,
    required String key,
    String? parentId,
  }) => _guard(() async {
    final model = await _remote.post(episodeId, body, key, parentId);
    final comment = model.toEntity();
    if (comment == null) {
      throw const ValidationFailure('Could not post your comment.');
    }
    return comment;
  });

  @override
  Future<void> setLike(String commentId, {required bool liked}) =>
      _guard(() => _remote.setLike(commentId, liked));

  @override
  Future<void> delete(String commentId) =>
      _guard(() => _remote.delete(commentId));

  @override
  Future<void> report(String commentId, String reason) =>
      _guard(() => _remote.report(commentId, reason));

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'Comment request failed: ${error.type.name} '
        'status=${error.response?.statusCode}',
        error: error,
      );
      final data = error.response?.data;
      final status = error.response?.statusCode ?? 0;
      if (status >= 400 &&
          status < 500 &&
          data is Map &&
          data['detail'] is String) {
        throw ValidationFailure(data['detail'] as String);
      }
      throw const NetworkFailure(
        'Something went wrong. Check your connection.',
      );
    }
  }
}
