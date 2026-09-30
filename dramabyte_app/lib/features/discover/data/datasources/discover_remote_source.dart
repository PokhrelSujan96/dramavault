import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';

final class DiscoverRemoteSource {
  DiscoverRemoteSource(this._client);

  static const pageSize = 6;
  final ApiClient _client;

  Future<ReelPageModel> page(String? cursor) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/discover',
      queryParameters: {'limit': pageSize, 'cursor': ?cursor},
    );
    return ReelPageModel.fromJson(response.data ?? const {});
  }
}
