import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/history/data/models/history_models.dart';

final class HistoryRemoteSource {
  HistoryRemoteSource(this._client);

  final ApiClient _client;

  Future<HistoryPageModel> page(String? cursor, int limit) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/history',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    return HistoryPageModel.fromJson(response.data ?? const {});
  }

  Future<void> record(String episodeId, int seconds) async {
    await _client.dio.put<void>(
      '/history/$episodeId',
      data: {'position_seconds': seconds},
    );
  }

  Future<void> remove(String? episodeId) async {
    await _client.dio.delete<void>(
      episodeId == null ? '/history' : '/history/$episodeId',
    );
  }
}
