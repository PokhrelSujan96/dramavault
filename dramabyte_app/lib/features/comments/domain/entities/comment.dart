import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  const Comment({
    required this.id,
    required this.episodeId,
    required this.body,
    required this.authorId,
    this.parentId,
    this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.liked = false,
    this.authorName = 'User',
    this.authorAvatar,
    this.isMine = false,
    this.pending = false,
  });

  final String id;
  final String episodeId;
  final String? parentId;
  final String body;
  final DateTime? createdAt;
  final int likeCount;
  final int replyCount;
  final bool liked;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final bool isMine;
  final bool pending;

  bool get isReply => parentId != null;

  Comment copyWith({
    int? likeCount,
    int? replyCount,
    bool? liked,
    bool? pending,
  }) => Comment(
    id: id,
    episodeId: episodeId,
    body: body,
    authorId: authorId,
    parentId: parentId,
    createdAt: createdAt,
    likeCount: likeCount ?? this.likeCount,
    replyCount: replyCount ?? this.replyCount,
    liked: liked ?? this.liked,
    authorName: authorName,
    authorAvatar: authorAvatar,
    isMine: isMine,
    pending: pending ?? this.pending,
  );

  @override
  List<Object?> get props => [
    id,
    episodeId,
    parentId,
    body,
    createdAt,
    likeCount,
    replyCount,
    liked,
    authorId,
    authorName,
    authorAvatar,
    isMine,
    pending,
  ];
}
