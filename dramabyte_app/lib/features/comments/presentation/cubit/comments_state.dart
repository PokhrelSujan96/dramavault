import 'package:dramabyte_app/features/comments/domain/entities/comment.dart';
import 'package:dramabyte_app/features/comments/domain/entities/comment_page.dart';
import 'package:equatable/equatable.dart';

enum CommentsStatus { loading, ready, failure }

class RepliesState extends Equatable {
  const RepliesState({
    this.items = const [],
    this.nextCursor,
    this.loading = false,
    this.expanded = false,
    this.loaded = false,
  });

  final List<Comment> items;
  final String? nextCursor;
  final bool loading;
  final bool expanded;
  final bool loaded;

  RepliesState copyWith({
    List<Comment>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loading,
    bool? expanded,
    bool? loaded,
  }) => RepliesState(
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loading: loading ?? this.loading,
    expanded: expanded ?? this.expanded,
    loaded: loaded ?? this.loaded,
  );

  @override
  List<Object?> get props => [items, nextCursor, loading, expanded, loaded];
}

class CommentsState extends Equatable {
  const CommentsState({
    this.status = CommentsStatus.loading,
    this.sort = CommentSort.top,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.replies = const {},
    this.replyTo,
    this.error,
    this.notice,
    this.noticeSeq = 0,
  });

  final CommentsStatus status;
  final CommentSort sort;
  final List<Comment> items;
  final String? nextCursor;
  final bool loadingMore;
  final Map<String, RepliesState> replies;
  final Comment? replyTo;
  final String? error;
  final String? notice;
  final int noticeSeq;

  RepliesState repliesOf(String id) => replies[id] ?? const RepliesState();

  CommentsState copyWith({
    CommentsStatus? status,
    CommentSort? sort,
    List<Comment>? items,
    String? nextCursor,
    bool clearCursor = false,
    bool? loadingMore,
    Map<String, RepliesState>? replies,
    Comment? replyTo,
    bool clearReply = false,
    String? error,
    String? notice,
  }) => CommentsState(
    status: status ?? this.status,
    sort: sort ?? this.sort,
    items: items ?? this.items,
    nextCursor: clearCursor ? null : nextCursor ?? this.nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    replies: replies ?? this.replies,
    replyTo: clearReply ? null : replyTo ?? this.replyTo,
    error: error,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    status,
    sort,
    items,
    nextCursor,
    loadingMore,
    replies,
    replyTo,
    error,
    notice,
    noticeSeq,
  ];
}
