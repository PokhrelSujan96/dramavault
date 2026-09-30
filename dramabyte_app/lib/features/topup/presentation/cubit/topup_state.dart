part of 'topup_cubit.dart';

class TopupState extends Equatable {
  const TopupState({
    this.purchasingId,
    this.notice,
    this.noticeSeq = 0,
    this.credited,
  });

  final String? purchasingId;
  final String? notice;
  final int noticeSeq;
  final TopupOrder? credited;

  TopupState copyWith({
    String? purchasingId,
    bool clearPurchasing = false,
    String? notice,
    TopupOrder? credited,
  }) => TopupState(
    purchasingId: clearPurchasing ? null : purchasingId ?? this.purchasingId,
    notice: notice,
    noticeSeq: notice == null ? noticeSeq : noticeSeq + 1,
    credited: credited,
  );

  @override
  List<Object?> get props => [purchasingId, notice, noticeSeq, credited];
}
