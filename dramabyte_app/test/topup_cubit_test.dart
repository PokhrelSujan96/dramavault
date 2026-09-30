import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';
import 'package:dramabyte_app/features/topup/domain/gateways/payment_gateway.dart';
import 'package:dramabyte_app/features/topup/domain/repositories/topup_repository.dart';
import 'package:dramabyte_app/features/topup/domain/usecases/topup_use_cases.dart';
import 'package:dramabyte_app/features/topup/presentation/cubit/topup_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements TopupRepository {
  int created = 0;
  int confirms = 0;
  Failure? confirmFailure;

  @override
  Future<List<CoinPackage>?> cachedPackages() async => null;

  @override
  Future<List<CoinPackage>> packages() async => const [];

  @override
  Stream<void> packageChanges() => const Stream.empty();

  @override
  Future<TopupOrder> createOrder(String packageId) async {
    created++;
    return TopupOrder(id: 'o$created', packageId: packageId, status: 'pending');
  }

  @override
  Future<TopupOrder> confirm(String orderId, String? receipt) async {
    confirms++;
    final failure = confirmFailure;
    if (failure != null) throw failure;
    return TopupOrder(id: orderId, packageId: 'p', status: 'completed');
  }
}

class _Gateway implements PaymentGateway {
  @override
  Future<String?> pay(CoinPackage package, TopupOrder order) async => null;
}

void main() {
  const package = CoinPackage(id: 'coins_60', coins: 60, bonusCoins: 5);
  late _FakeRepository repository;
  late TopupCubit cubit;

  setUp(() {
    repository = _FakeRepository();
    cubit = TopupCubit(
      CreateTopupOrder(repository),
      ConfirmTopup(repository),
      _Gateway(),
    );
  });

  test('successful purchase reports the total coins added', () async {
    await cubit.purchase(package);
    expect(cubit.state.credited?.isCompleted, isTrue);
    expect(cubit.state.notice, contains('coins added to your wallet'));
    expect(cubit.state.purchasingId, isNull);
  });

  test('a network failure keeps the order so a retry reuses it', () async {
    repository.confirmFailure = const NetworkFailure('offline');
    await cubit.purchase(package);
    expect(cubit.state.credited, isNull);
    repository.confirmFailure = null;
    await cubit.purchase(package);
    expect(repository.created, 1);
    expect(cubit.state.credited, isNotNull);
  });

  test('a server rejection discards the order and starts fresh', () async {
    repository.confirmFailure = const ValidationFailure('expired');
    await cubit.purchase(package);
    repository.confirmFailure = null;
    await cubit.purchase(package);
    expect(repository.created, 2);
  });

  test('ignores a second purchase while one is in flight', () async {
    final first = cubit.purchase(package);
    await cubit.purchase(package);
    await first;
    expect(repository.created, 1);
    expect(repository.confirms, 1);
  });
}
