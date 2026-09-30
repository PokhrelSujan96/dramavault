import 'package:dramabyte_app/features/library/domain/entities/library_item.dart';

final class LibraryItemModel {
  const LibraryItemModel(this.json);

  final Map<String, dynamic> json;

  LibraryItem? toEntity() {
    final id = _string('series_id');
    if (id == null) return null;
    final count = json['episode_count'];
    final free = json['free_episode_count'];
    return LibraryItem(
      seriesId: id,
      title: _string('title') ?? '',
      genre: _string('genre') ?? '',
      thumbnailUrl: _string('thumbnail_url') ?? '',
      episodeCount: count is num ? count.toInt() : 0,
      freeEpisodeCount: free is num ? free.toInt() : null,
      savedAt: DateTime.tryParse(_string('saved_at') ?? '')?.toLocal(),
    );
  }

  String? _string(String key) {
    final value = json[key];
    return value is String && value.isNotEmpty ? value : null;
  }
}
