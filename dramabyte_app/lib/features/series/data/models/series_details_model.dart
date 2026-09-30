import 'package:dramabyte_app/features/ratings/data/models/rating_summary_model.dart';
import 'package:dramabyte_app/features/series/domain/entities/episode_summary.dart';
import 'package:dramabyte_app/features/series/domain/entities/series_details.dart';

final class SeriesDetailsModel {
  const SeriesDetailsModel(this.json);

  final Map<String, dynamic> json;

  SeriesDetails? toEntity() {
    final id = _string(json, 'series_id');
    if (id == null) return null;
    final raw = json['episodes'];
    final free = json['free_episode_count'];
    return SeriesDetails(
      seriesId: id,
      title: _string(json, 'title') ?? '',
      description: _string(json, 'description') ?? '',
      genre: _string(json, 'genre') ?? '',
      thumbnailUrl: _string(json, 'thumbnail_url') ?? '',
      freeEpisodeCount: free is num ? free.toInt() : null,
      rating: RatingSummaryModel({
        'average': json['rating_average'],
        'count': json['rating_count'],
        'my_rating': json['my_rating'],
      }).toEntity(),
      episodes: [
        if (raw is List)
          for (final item in raw)
            if (item is Map<String, dynamic>) ?_episode(item),
      ],
    );
  }

  static EpisodeSummary? _episode(Map<String, dynamic> json) {
    final id = _string(json, 'episode_id');
    final number = json['episode_number'];
    if (id == null || number is! num) return null;
    final duration = json['duration_seconds'];
    return EpisodeSummary(
      episodeId: id,
      episodeNumber: number.toInt(),
      title: _string(json, 'title') ?? '',
      durationSeconds: duration is num ? duration.toInt() : 0,
      thumbnailUrl: _string(json, 'thumbnail_url') ?? '',
      locked: json['locked'] == true,
    );
  }

  static String? _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
