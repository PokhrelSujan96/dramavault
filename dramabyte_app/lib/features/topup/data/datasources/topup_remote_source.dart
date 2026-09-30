import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/topup/data/models/topup_models.dart';

final class TopupRemoteSource {
  TopupRemoteSource(this._client);

  final ApiClient _client;

  Future<List<CoinPackageModel>> packages() async {
    final response = await _client.dio.get<List<dynamic>>('/topup/packages');
    return [
      for (final item in response.data ?? const [])
        if (item is Map<String, dynamic>) CoinPackageModel(item),
    ];
  }

  Future<TopupOrderModel> createOrder(String packageId, String key) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/topup/orders',
      data: {'package_id': packageId},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    return TopupOrderModel(response.data ?? const {});
  }

  Future<TopupOrderModel> confirm(String orderId, String? receipt) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/topup/orders/$orderId/confirm',
      data: {'receipt': receipt},
    );
    return TopupOrderModel(response.data ?? const {});
  }
}
