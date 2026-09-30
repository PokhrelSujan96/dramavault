import 'package:equatable/equatable.dart';

class SearchResult extends Equatable {
  const SearchResult({
    required this.seriesId,
    required this.title,
    this.genre = '',
    this.thumbnailUrl = '',
    this.episodeCount = 0,
    this.freeEpisodeCount,
  });

  final String seriesId;
  final String title;
  final String genre;
  final String thumbnailUrl;
  final int episodeCount;
  final int? freeEpisodeCount;

  String get subtitle {
    final episodes = freeEpisodeCount == null
        ? '$episodeCount ${episodeCount == 1 ? 'episode' : 'episodes'}'
        : '$freeEpisodeCount eps free';
    return [if (genre.isNotEmpty) genre, episodes].join(' · ');
  }

  @override
  List<Object?> get props => [
    seriesId,
    title,
    genre,
    thumbnailUrl,
    episodeCount,
    freeEpisodeCount,
  ];
}
