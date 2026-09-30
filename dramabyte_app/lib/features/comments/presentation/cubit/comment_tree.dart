import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/presentation/cubit/comments_state.dart';

extension CommentTree on CommentsState {
  Comment? find(String id) {
    for (final comment in items) {
      if (comment.id == id) return comment;
    }
    for (final replies in replies.values) {
      for (final reply in replies.items) {
        if (reply.id == id) return reply;
      }
    }
    return null;
  }

  CommentsState mutate(String id, Comment Function(Comment) change) {
    final top = items.any((c) => c.id == id);
    if (top) {
      return copyWith(
        items: [for (final c in items) c.id == id ? change(c) : c],
      );
    }
    return copyWith(
      replies: {
        for (final entry in replies.entries)
          entry.key: entry.value.items.any((c) => c.id == id)
              ? entry.value.copyWith(
                  items: [
                    for (final c in entry.value.items)
                      c.id == id ? change(c) : c,
                  ],
                )
              : entry.value,
      },
    );
  }

  CommentsState addLocal(Comment comment) {
    final parent = comment.parentId;
    if (parent == null) return copyWith(items: [comment, ...items]);
    final current = repliesOf(parent);
    return mutate(
      parent,
      (c) => c.copyWith(replyCount: c.replyCount + 1),
    ).copyWith(
      replies: {
        ...replies,
        parent: current.copyWith(
          items: [...current.items, comment],
          expanded: true,
        ),
      },
    );
  }

  CommentsState replaceLocal(String tempId, Comment saved) {
    if (items.any((c) => c.id == tempId)) {
      return copyWith(
        items: [for (final c in items) c.id == tempId ? saved : c],
      );
    }
    return copyWith(
      replies: {
        for (final entry in replies.entries)
          entry.key: entry.value.items.any((c) => c.id == tempId)
              ? entry.value.copyWith(
                  items: [
                    for (final c in entry.value.items)
                      c.id == tempId ? saved : c,
                  ],
                )
              : entry.value,
      },
    );
  }

  CommentsState removeLocal(Comment comment) {
    final parent = comment.parentId;
    if (parent == null) {
      return copyWith(
        items: [
          for (final c in items)
            if (c.id != comment.id) c,
        ],
        replies: {...replies}..remove(comment.id),
      );
    }
    final current = repliesOf(parent);
    return mutate(
      parent,
      (c) => c.copyWith(replyCount: c.replyCount > 0 ? c.replyCount - 1 : 0),
    ).copyWith(
      replies: {
        ...replies,
        parent: current.copyWith(
          items: [
            for (final c in current.items)
              if (c.id != comment.id) c,
          ],
        ),
      },
    );
  }

  List<Comment> mergeUnique(List<Comment> existing, List<Comment> incoming) {
    final known = {for (final c in existing) c.id};
    return [
      ...existing,
      for (final c in incoming)
        if (!known.contains(c.id)) c,
    ];
  }
}
