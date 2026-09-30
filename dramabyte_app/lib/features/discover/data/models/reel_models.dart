import 'package:dramabyte_app/features/discover/domain/entities/reel.dart';
import 'package:dramabyte_app/features/discover/domain/entities/reel_page.dart';
import 'package:dramabyte_app/features/ratings/data/models/rating_summary_model.dart';

final class ReelModel {
  const ReelModel(this.json);

  final Map<String, dynamic> json;

  Reel? toEntity() {
    final episodeId = _string('episode_id');
    if (episodeId == null) return null;
    return Reel(
      episodeId: episodeId,
      seriesId: _string('series_id') ?? '',
      title: _string('title') ?? '',
      description: _string('description') ?? '',
      genre: _string('genre') ?? '',
      thumbnailUrl: _string('thumbnail_url') ?? '',
      episodeNumber: _int('episode_number', 1),
      durationSeconds: _int('duration_seconds'),
      videoUrl: _string('video_url') ?? '',
      videoVariants: _stringMap('video_variants'),
      videoRevision: _string('video_revision') ?? '',
      publishedCount: _int('published_count'),
      likes: _int('likes'),
      views: _int('views'),
      liked: json['liked'] == true,
      comments: _int('comments'),
      rating: RatingSummaryModel({
        'average': json['rating_average'],
        'count': json['rating_count'],
        'my_rating': json['my_rating'],
      }).toEntity(),
    );
  }

  String? _string(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int _int(String key, [int fallback = 0]) {
    final value = json[key];
    return value is num ? value.toInt() : fallback;
  }

  Map<String, String> _stringMap(String key) {
    final value = json[key];
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.key is String && entry.value is String)
          entry.key as String: entry.value as String,
    };
  }
}

final class ReelPageModel {
  const ReelPageModel(this.items, this.nextCursor);

  factory ReelPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final cursor = json['next_cursor'];
    return ReelPageModel([
      if (raw is List)
        for (final item in raw)
          if (item is Map<String, dynamic>) ReelModel(item),
    ], cursor is String && cursor.isNotEmpty ? cursor : null);
  }

  final List<ReelModel> items;
  final String? nextCursor;

  ReelPage toEntity() =>
      ReelPage([for (final item in items) ?item.toEntity()], nextCursor);
}
