import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/cache/json_cache.dart';
import 'package:dramabyte_app/core/errors/failure.dart';
import 'package:dramabyte_app/core/logging/app_logger.dart';
import 'package:dramabyte_app/core/realtime/realtime_service.dart';
import 'package:dramabyte_app/features/topup/data/datasources/topup_remote_source.dart';
import 'package:dramabyte_app/features/topup/data/models/topup_models.dart';
import 'package:dramabyte_app/features/topup/domain/entities/coin_package.dart';
import 'package:dramabyte_app/features/topup/domain/entities/topup_order.dart';
import 'package:dramabyte_app/features/topup/domain/repositories/topup_repository.dart';

final class TopupRepositoryImpl implements TopupRepository {
  TopupRepositoryImpl(this._remote, this._cache, this._realtime);

  static const _cacheKey = 'cache_coin_packages';
  final TopupRemoteSource _remote;
  final JsonCache _cache;
  final RealtimeService _realtime;
  final _random = Random.secure();

  @override
  Future<List<CoinPackage>?> cachedPackages() async {
    final items = (await _cache.read(_cacheKey))?['items'];
    if (items is! List) return null;
    return [
      for (final item in items)
        if (item is Map<String, dynamic>) CoinPackageModel(item).toEntity(),
    ];
  }

  @override
  Future<List<CoinPackage>> packages() => _guard(() async {
    final models = await _remote.packages();
    await _cache.write(_cacheKey, {
      'items': [for (final model in models) model.json],
    });
    return [for (final model in models) model.toEntity()];
  });

  @override
  Stream<void> packageChanges() => _realtime.changes('coin_packages');

  @override
  Future<TopupOrder> createOrder(String packageId) => _guard(
    () async => (await _remote.createOrder(packageId, _key())).toEntity(),
  );

  @override
  Future<TopupOrder> confirm(String orderId, String? receipt) =>
      _guard(() async => (await _remote.confirm(orderId, receipt)).toEntity());

  String _key() =>
      List.generate(32, (_) => _random.nextInt(16).toRadixString(16)).join();

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (error) {
      AppLogger.error(
        'Top-up request failed: ${error.type.name} '
        'status=${error.response?.statusCode} body=${error.response?.data}',
        error: error,
      );
      final data = error.response?.data;
      final status = error.response?.statusCode ?? 0;
      if (status >= 400 &&
          status < 500 &&
          data is Map &&
          data['detail'] is String) {
        throw ValidationFailure(data['detail'] as String);
      }
      throw const NetworkFailure('Unable to reach DramaByte. Try again.');
    }
  }
}
