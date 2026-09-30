import 'package:bloc/bloc.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';
import 'package:dramabyte_app/features/topup/domain/gateways/payment_gateway.dart';
import 'package:dramabyte_app/features/topup/domain/usecases/topup_use_cases.dart';
import 'package:equatable/equatable.dart';

part 'topup_state.dart';

class TopupCubit extends Cubit<TopupState> {
  TopupCubit(this._create, this._confirm, this._gateway)
    : super(const TopupState());

  final CreateTopupOrder _create;
  final ConfirmTopup _confirm;
  final PaymentGateway _gateway;
  TopupOrder? _pending;

  Future<void> purchase(CoinPackage package) async {
    if (state.purchasingId != null) return;
    emit(state.copyWith(purchasingId: package.id));
    try {
      final resumable = _pending?.packageId == package.id ? _pending : null;
      final order = resumable ?? await _create(package.id);
      _pending = order;
      final receipt = await _gateway.pay(package, order);
      final done = await _confirm(ConfirmParams(order.id, receipt));
      _pending = null;
      emit(
        state.copyWith(
          clearPurchasing: true,
          notice: '${done.coins + done.bonusCoins} coins added to your wallet',
          credited: done,
        ),
      );
    } on Failure catch (failure) {
      if (failure is ValidationFailure) _pending = null;
      emit(state.copyWith(clearPurchasing: true, notice: failure.message));
    }
  }
}
