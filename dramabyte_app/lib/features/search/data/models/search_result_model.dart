import 'package:dramabyte_app/features/search/domain/entities/search_result.dart';

final class SearchResultModel {
  const SearchResultModel(this.json);

  final Map<String, dynamic> json;

  SearchResult? toEntity() {
    final id = _string('series_id');
    if (id == null) return null;
    final count = json['episode_count'];
    final free = json['free_episode_count'];
    return SearchResult(
      seriesId: id,
      title: _string('title') ?? '',
      genre: _string('genre') ?? '',
      thumbnailUrl: _string('thumbnail_url') ?? '',
      episodeCount: count is num ? count.toInt() : 0,
      freeEpisodeCount: free is num ? free.toInt() : null,
    );
  }

  String? _string(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
