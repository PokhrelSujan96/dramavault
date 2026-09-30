import 'package:dramabyte_app/core/network/api_client.dart';

final class AccountRemoteSource {
  AccountRemoteSource(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> preferences() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/account/preferences',
    );
    return response.data ?? const {};
  }

  Future<void> savePreferences(Map<String, bool> body) {
    return _client.dio.put<void>('/account/preferences', data: body);
  }

  Future<void> delete(String idToken) {
    return _client.dio.post<void>(
      '/account/delete',
      data: {'id_token': idToken},
    );
  }
}
