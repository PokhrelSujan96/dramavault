import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/profile/data/models/user_profile_model.dart';

final class ProfileRemoteSource {
  ProfileRemoteSource(this._client);

  final ApiClient _client;

  Future<UserProfileModel> me() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/profile/me');
    return UserProfileModel(response.data ?? const {});
  }
}
