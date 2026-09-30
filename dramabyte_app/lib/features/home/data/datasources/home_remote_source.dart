import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/home/data/models/home_models.dart';

final class HomeRemoteSource {
  HomeRemoteSource(this._client);

  final ApiClient _client;

  Future<HomeFeedModel> feed() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/home');
    return HomeFeedModel(response.data ?? const {});
  }
}
