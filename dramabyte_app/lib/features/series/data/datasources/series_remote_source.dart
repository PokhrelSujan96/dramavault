import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/discover/data/models/reel_models.dart';
import 'package:dramabyte_app/features/series/data/models/series_details_model.dart';

final class SeriesRemoteSource {
  SeriesRemoteSource(this._client);

  final ApiClient _client;

  Future<SeriesDetailsModel> details(String seriesId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/series/$seriesId',
    );
    return SeriesDetailsModel(response.data ?? const {});
  }

  Future<List<ReelModel>> playlist(String seriesId) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/series/$seriesId/playlist',
    );
    return [
      for (final item in response.data ?? const [])
        if (item is Map<String, dynamic>) ReelModel(item),
    ];
  }
}
