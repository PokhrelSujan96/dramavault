import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/search/data/models/search_result_model.dart';

final class SearchRemoteSource {
  SearchRemoteSource(this._client);

  final ApiClient _client;

  Future<List<SearchResultModel>> search(String query) async {
    final response = await _client.dio.get<List<dynamic>>(
      '/search',
      queryParameters: {'q': query, 'limit': 20},
    );
    return [
      for (final item in response.data ?? const [])
        if (item is Map<String, dynamic>) SearchResultModel(item),
    ];
  }
}
