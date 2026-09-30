part of 'discover_cubit.dart';

enum DiscoverStatus { loading, ready, failure }

class DiscoverState extends Equatable {
  const DiscoverState({
    this.status = DiscoverStatus.loading,
    this.reels = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.offline = false,
    this.error,
  });

  final DiscoverStatus status;
  final List<Reel> reels;
  final String? nextCursor;
  final bool loadingMore;
  final bool offline;
  final String? error;

  bool get hasMore => nextCursor != null;

  DiscoverState copyWith({
    DiscoverStatus? status,
    List<Reel>? reels,
    String? nextCursor,
    bool? loadingMore,
    bool? offline,
    String? error,
  }) => DiscoverState(
    status: status ?? this.status,
    reels: reels ?? this.reels,
    nextCursor: nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    offline: offline ?? this.offline,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    reels,
    nextCursor,
    loadingMore,
    offline,
    error,
  ];
}
