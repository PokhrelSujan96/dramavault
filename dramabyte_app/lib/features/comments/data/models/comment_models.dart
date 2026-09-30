import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';

final class CommentModel {
  const CommentModel(this.json);

  final Map<String, dynamic> json;

  Comment? toEntity() {
    final id = _string('id');
    final authorId = _string('author_id');
    final body = json['body'];
    if (id == null || authorId == null || body is! String) return null;
    return Comment(
      id: id,
      episodeId: _string('episode_id') ?? '',
      parentId: _string('parent_id'),
      body: body,
      createdAt: DateTime.tryParse(_string('created_at') ?? '')?.toLocal(),
      likeCount: _int('like_count'),
      replyCount: _int('reply_count'),
      liked: json['liked'] == true,
      authorId: authorId,
      authorName: _string('author_name') ?? 'User',
      authorAvatar: _string('author_avatar'),
      isMine: json['is_mine'] == true,
    );
  }

  String? _string(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _int(String key) {
    final value = json[key];
    return value is num ? value.toInt() : 0;
  }
}

final class CommentPageModel {
  const CommentPageModel(this.items, this.nextCursor);

  factory CommentPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final cursor = json['next_cursor'];
    return CommentPageModel([
      if (raw is List)
        for (final item in raw)
          if (item is Map<String, dynamic>) CommentModel(item),
    ], cursor is String && cursor.isNotEmpty ? cursor : null);
  }

  final List<CommentModel> items;
  final String? nextCursor;

  CommentPage toEntity() =>
      CommentPage([for (final item in items) ?item.toEntity()], nextCursor);
}
