import 'package:dramabyte_app/core/network/api_client.dart';

final class EngagementRemoteSource {
  EngagementRemoteSource(this._client);

  final ApiClient _client;

  Future<void> setLike(String episodeId, {required bool liked}) async {
    await _client.dio.post<void>(
      '/engagement/episodes/$episodeId/likes',
      data: {'liked': liked},
    );
  }

  Future<void> sendViews(String batchId, Map<String, int> items) async {
    await _client.dio.post<void>(
      '/views/batch',
      data: {
        'batch_id': batchId,
        'items': [
          for (final entry in items.entries)
            {'episode_id': entry.key, 'count': entry.value},
        ],
      },
    );
  }
}
