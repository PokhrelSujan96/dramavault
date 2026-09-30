class CommentsArgs {
  const CommentsArgs({
    required this.episodeId,
    required this.authorId,
    this.authorName = 'You',
    this.authorAvatar,
  });

  final String episodeId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
}
