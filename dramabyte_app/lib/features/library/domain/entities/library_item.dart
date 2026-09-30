import 'package:equatable/equatable.dart';

class LibraryItem extends Equatable {
  const LibraryItem({
    required this.seriesId,
    required this.title,
    this.genre = '',
    this.thumbnailUrl = '',
    this.episodeCount = 0,
    this.freeEpisodeCount,
    this.savedAt,
  });

  final String seriesId;
  final String title;
  final String genre;
  final String thumbnailUrl;
  final int episodeCount;
  final int? freeEpisodeCount;
  final DateTime? savedAt;

  String get subtitle {
    final episodes = freeEpisodeCount == null
        ? '$episodeCount ${episodeCount == 1 ? 'episode' : 'episodes'}'
        : '$freeEpisodeCount eps free · All $episodeCount';
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
    savedAt,
  ];
}
