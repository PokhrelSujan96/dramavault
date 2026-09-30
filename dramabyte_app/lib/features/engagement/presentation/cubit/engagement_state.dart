part of 'engagement_cubit.dart';

class EngagementState extends Equatable {
  const EngagementState({
    this.episodes = const {},
    this.notice,
    this.noticeSeq = 0,
  });

  final Map<String, EpisodeEngagement> episodes;
  final String? notice;
  final int noticeSeq;

  EpisodeEngagement of(String episodeId) =>
      episodes[episodeId] ?? const EpisodeEngagement();

  EngagementState copyWith({
    Map<String, EpisodeEngagement>? episodes,
    String? notice,
  }) => EngagementState(
    episodes: episodes ?? this.episodes,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [episodes, notice, noticeSeq];
}
