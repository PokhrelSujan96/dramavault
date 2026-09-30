import 'package:dramabyte_app/core/format/compact_count.dart';
import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:equatable/equatable.dart';

class SeriesCard extends Equatable {
  const SeriesCard({
    required this.seriesId,
    required this.title,
    this.description = '',
    this.genre = '',
    this.thumbnailUrl = '',
    this.episodeCount = 0,
    this.freeEpisodeCount,
    this.views = 0,
    this.rating = const RatingSummary(),
  });

  final String seriesId;
  final String title;
  final String description;
  final String genre;
  final String thumbnailUrl;
  final int episodeCount;
  final int? freeEpisodeCount;
  final int views;
  final RatingSummary rating;

  String get subtitle =>
      freeEpisodeCount == null ? episodesLabel : '$freeEpisodeCount eps free';

  String get viewsLabel => '${compactCount(views)} views';

  String get episodesLabel =>
      '$episodeCount ${episodeCount == 1 ? 'episode' : 'episodes'}';

  @override
  List<Object?> get props => [
    seriesId,
    title,
    description,
    genre,
    thumbnailUrl,
    episodeCount,
    freeEpisodeCount,
    views,
    rating,
  ];
}
