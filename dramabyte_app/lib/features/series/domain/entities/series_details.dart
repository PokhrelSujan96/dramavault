import 'dart:math';

import 'package:dramabyte_app/features/ratings/domain/entities/rating_summary.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_range.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:equatable/equatable.dart';

class SeriesDetails extends Equatable {
  const SeriesDetails({
    required this.seriesId,
    required this.title,
    required this.episodes,
    this.description = '',
    this.genre = '',
    this.thumbnailUrl = '',
    this.freeEpisodeCount,
    this.rating = const RatingSummary(),
  });

  static const rangeSize = 15;

  final String seriesId;
  final String title;
  final String description;
  final String genre;
  final String thumbnailUrl;
  final int? freeEpisodeCount;
  final RatingSummary rating;
  final List<EpisodeSummary> episodes;

  int get episodeCount => episodes.length;

  String get freeLabel =>
      freeEpisodeCount == null ? '' : '$freeEpisodeCount eps free';

  String get totalLabel => 'All $episodeCount episodes';

  List<EpisodeRange> get ranges => [
    for (var i = 0; i < episodes.length; i += rangeSize)
      EpisodeRange(episodes.sublist(i, min(i + rangeSize, episodes.length))),
  ];

  @override
  List<Object?> get props => [
    seriesId,
    title,
    description,
    genre,
    thumbnailUrl,
    freeEpisodeCount,
    rating,
    episodes,
  ];
}
