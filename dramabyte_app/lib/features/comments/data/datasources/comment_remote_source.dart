import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/comments/data/models/comment_models.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';

final class CommentRemoteSource {
  CommentRemoteSource(this._client);

  static const pageSize = 20;
  static const replyPageSize = 10;
  final ApiClient _client;

  Future<CommentPageModel> list(
    String episodeId,
    CommentSort sort,
    String? cursor,
  ) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/comments/episodes/$episodeId',
      queryParameters: {
        'sort': sort == CommentSort.top ? 'top' : 'new',
        'limit': pageSize,
        'cursor': ?cursor,
      },
    );
    return CommentPageModel.fromJson(response.data ?? const {});
  }

  Future<CommentPageModel> replies(String commentId, String? cursor) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/comments/$commentId/replies',
      queryParameters: {'limit': replyPageSize, 'cursor': ?cursor},
    );
    return CommentPageModel.fromJson(response.data ?? const {});
  }

  Future<CommentModel> post(
    String episodeId,
    String body,
    String key,
    String? parentId,
  ) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/comments/episodes/$episodeId',
      data: {'body': body, 'idempotency_key': key, 'parent_id': ?parentId},
    );
    return CommentModel({...?response.data, 'is_mine': true});
  }

  Future<void> setLike(String commentId, bool liked) async {
    await _client.dio.put<void>(
      '/comments/$commentId/like',
      data: {'liked': liked},
    );
  }

  Future<void> delete(String commentId) async {
    await _client.dio.delete<void>('/comments/$commentId');
  }

  Future<void> report(String commentId, String reason) async {
    await _client.dio.post<void>(
      '/comments/$commentId/report',
      data: {'reason': reason},
    );
  }
}
