import 'package:dramabyte_app/features/home/domain/entities/genre_rail.dart';
import 'package:dramabyte_app/features/home/domain/entities/home_feed.dart';
import 'package:dramabyte_app/features/home/domain/entities/series_card.dart';
import 'package:dramabyte_app/features/ratings/data/models/rating_summary_model.dart';

final class HomeFeedModel {
  const HomeFeedModel(this.json);

  final Map<String, dynamic> json;

  HomeFeed toEntity() {
    final rails = json['genres'];
    return HomeFeed(
      featured: _cards(json['featured']),
      trending: _cards(json['trending']),
      genres: [
        if (rails is List)
          for (final rail in rails)
            if (rail is Map<String, dynamic> && _string(rail, 'genre') != null)
              GenreRail(_string(rail, 'genre')!, _cards(rail['items'])),
      ],
    );
  }

  static List<SeriesCard> _cards(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (item is Map<String, dynamic>) ?_card(item),
  ];

  static SeriesCard? _card(Map<String, dynamic> json) {
    final id = _string(json, 'series_id');
    if (id == null) return null;
    final count = json['episode_count'];
    final free = json['free_episode_count'];
    final views = json['views'];
    return SeriesCard(
      seriesId: id,
      title: _string(json, 'title') ?? '',
      description: _string(json, 'description') ?? '',
      genre: _string(json, 'genre') ?? '',
      thumbnailUrl: _string(json, 'thumbnail_url') ?? '',
      episodeCount: count is num ? count.toInt() : 0,
      freeEpisodeCount: free is num ? free.toInt() : null,
      views: views is num ? views.toInt() : 0,
      rating: RatingSummaryModel({
        'average': json['rating_average'],
        'count': json['rating_count'],
      }).toEntity(),
    );
  }

  static String? _string(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
