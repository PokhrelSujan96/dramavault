import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/library/data/models/library_item_model.dart';

final class LibraryRemoteSource {
  LibraryRemoteSource(this._client);

  final ApiClient _client;

  Future<List<LibraryItemModel>> list() async {
    final response = await _client.dio.get<List<dynamic>>('/library');
    return [
      for (final item in response.data ?? const [])
        if (item is Map<String, dynamic>) LibraryItemModel(item),
    ];
  }

  Future<void> add(String seriesId) async {
    await _client.dio.put<void>('/library/$seriesId');
  }

  Future<void> remove(String seriesId) async {
    await _client.dio.delete<void>('/library/$seriesId');
  }
}
