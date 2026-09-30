import 'package:equatable/equatable.dart';

class EpisodeSummary extends Equatable {
  const EpisodeSummary({
    required this.episodeId,
    required this.episodeNumber,
    this.title = '',
    this.durationSeconds = 0,
    this.thumbnailUrl = '',
    this.locked = false,
  });

  final String episodeId;
  final int episodeNumber;
  final String title;
  final int durationSeconds;
  final String thumbnailUrl;
  final bool locked;

  @override
  List<Object> get props => [
    episodeId,
    episodeNumber,
    title,
    durationSeconds,
    thumbnailUrl,
    locked,
  ];
}
