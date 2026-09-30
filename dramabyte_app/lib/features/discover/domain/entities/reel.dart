import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:equatable/equatable.dart';

class Reel extends Equatable {
  const Reel({
    required this.episodeId,
    required this.seriesId,
    required this.title,
    this.description = '',
    this.genre = '',
    this.thumbnailUrl = '',
    this.episodeNumber = 1,
    this.durationSeconds = 0,
    this.videoUrl = '',
    this.videoVariants = const {},
    this.videoRevision = '',
    this.publishedCount = 0,
    this.likes = 0,
    this.views = 0,
    this.liked = false,
    this.comments = 0,
    this.rating = const RatingSummary(),
  });

  final String episodeId;
  final String seriesId;
  final String title;
  final String description;
  final String genre;
  final String thumbnailUrl;
  final int episodeNumber;
  final int durationSeconds;
  final String videoUrl;
  final Map<String, String> videoVariants;
  final String videoRevision;
  final int publishedCount;
  final int likes;
  final int views;
  final bool liked;
  final int comments;
  final RatingSummary rating;

  String get episodeLabel => 'EP. $episodeNumber';

  String get likesLabel => compactCount(likes);

  String get viewsLabel => compactCount(views);

  @override
  List<Object> get props => [
    episodeId,
    seriesId,
    title,
    description,
    genre,
    thumbnailUrl,
    episodeNumber,
    durationSeconds,
    videoUrl,
    videoVariants,
    videoRevision,
    publishedCount,
    likes,
    views,
    liked,
    comments,
    rating,
  ];
}
