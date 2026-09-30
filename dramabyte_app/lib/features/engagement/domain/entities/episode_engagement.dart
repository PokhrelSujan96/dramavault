import 'package:equatable/equatable.dart';

class EpisodeEngagement extends Equatable {
  const EpisodeEngagement({
    this.views = 0,
    this.likes = 0,
    this.liked = false,
    this.comments = 0,
  });

  final int views;
  final int likes;
  final bool liked;
  final int comments;

  EpisodeEngagement copyWith({
    int? views,
    int? likes,
    bool? liked,
    int? comments,
  }) => EpisodeEngagement(
    views: views ?? this.views,
    likes: likes ?? this.likes,
    liked: liked ?? this.liked,
    comments: comments ?? this.comments,
  );

  @override
  List<Object> get props => [views, likes, liked, comments];
}
