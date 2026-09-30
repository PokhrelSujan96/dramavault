import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';

enum CommentSort { top, newest }

class CommentPage {
  const CommentPage(this.items, this.nextCursor);

  final List<Comment> items;
  final String? nextCursor;
}
