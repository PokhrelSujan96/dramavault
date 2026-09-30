import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';

class EpisodeRange {
  const EpisodeRange(this.episodes);

  final List<EpisodeSummary> episodes;

  String get label {
    final first = episodes.first.episodeNumber;
    final last = episodes.last.episodeNumber;
    return first == last ? '$first' : '$first-$last';
  }

  bool contains(String episodeId) =>
      episodes.any((episode) => episode.episodeId == episodeId);
}
