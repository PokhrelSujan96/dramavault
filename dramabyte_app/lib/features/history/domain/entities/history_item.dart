import 'package:equatable/equatable.dart';

class HistoryItem extends Equatable {
  const HistoryItem({
    required this.episodeId,
    required this.title,
    this.seriesId = '',
    this.episodeNumber = 1,
    this.thumbnailUrl = '',
    this.positionSeconds = 0,
    this.durationSeconds = 0,
    this.watchedAt,
  });

  final String episodeId;
  final String seriesId;
  final String title;
  final int episodeNumber;
  final String thumbnailUrl;
  final int positionSeconds;
  final int durationSeconds;
  final DateTime? watchedAt;

  String get episodeLabel => 'EP. $episodeNumber';

  double get progress => durationSeconds <= 0
      ? 0
      : (positionSeconds / durationSeconds).clamp(0.0, 1.0);

  bool get isCompleted => progress >= 0.95;

  String get watchedLabel {
    final at = watchedAt;
    if (at == null) return '';
    final ago = DateTime.now().difference(at);
    if (ago.inMinutes < 1) return 'Just now';
    if (ago.inHours < 1) return '${ago.inMinutes}m ago';
    if (ago.inDays < 1) return '${ago.inHours}h ago';
    if (ago.inDays < 7) return '${ago.inDays}d ago';
    return '${at.day}/${at.month}/${at.year}';
  }

  @override
  List<Object?> get props => [
    episodeId,
    seriesId,
    title,
    episodeNumber,
    thumbnailUrl,
    positionSeconds,
    durationSeconds,
    watchedAt,
  ];
}
