import 'package:dramabyte_app/features/history/domain/entities/history_item.dart';
import 'package:dramabyte_app/features/history/domain/entities/history_page.dart';

final class HistoryModel {
  const HistoryModel(this.json);

  final Map<String, dynamic> json;

  HistoryItem? toEntity() {
    final id = _string('episode_id');
    if (id == null) return null;
    return HistoryItem(
      episodeId: id,
      seriesId: _string('series_id') ?? '',
      title: _string('title') ?? '',
      episodeNumber: _int('episode_number', 1),
      thumbnailUrl: _string('thumbnail_url') ?? '',
      positionSeconds: _int('position_seconds'),
      durationSeconds: _int('duration_seconds'),
      watchedAt: DateTime.tryParse(_string('watched_at') ?? '')?.toLocal(),
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
}

final class HistoryPageModel {
  const HistoryPageModel(this.items, this.nextCursor);

  factory HistoryPageModel.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final cursor = json['next_cursor'];
    return HistoryPageModel([
      if (raw is List)
        for (final item in raw)
          if (item is Map<String, dynamic>) HistoryModel(item),
    ], cursor is String && cursor.isNotEmpty ? cursor : null);
  }

  final List<HistoryModel> items;
  final String? nextCursor;

  HistoryPage toEntity() =>
      HistoryPage([for (final item in items) ?item.toEntity()], nextCursor);
}
