part of 'history_list_cubit.dart';

enum HistoryListStatus { loading, ready, failure }

class HistoryListState extends Equatable {
  const HistoryListState({
    this.status = HistoryListStatus.loading,
    this.items = const [],
    this.nextCursor,
    this.loadingMore = false,
    this.error,
    this.notice,
    this.noticeSeq = 0,
  });

  final HistoryListStatus status;
  final List<HistoryItem> items;
  final String? nextCursor;
  final bool loadingMore;
  final String? error;
  final String? notice;
  final int noticeSeq;

  HistoryListState copyWith({
    HistoryListStatus? status,
    List<HistoryItem>? items,
    String? nextCursor,
    bool? loadingMore,
    String? error,
    String? notice,
  }) => HistoryListState(
    status: status ?? this.status,
    items: items ?? this.items,
    nextCursor: nextCursor,
    loadingMore: loadingMore ?? this.loadingMore,
    error: error,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
  );

  @override
  List<Object?> get props => [
    status,
    items,
    nextCursor,
    loadingMore,
    error,
    notice,
    noticeSeq,
  ];
}
