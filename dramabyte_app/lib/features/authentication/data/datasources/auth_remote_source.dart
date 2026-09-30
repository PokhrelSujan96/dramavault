import 'package:dio/dio.dart';
import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/authentication/data/models/auth_result_model.dart';

final class AuthRemoteSource {
  AuthRemoteSource(this._client);

  final ApiClient _client;

  Future<AuthResultModel> google(String idToken, String? referralCode) => _post(
    '/auth/google',
    {'id_token': idToken, 'referral_code': ?referralCode},
  );

  Future<AuthResultModel> _post(String path, Map<String, String> body) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      path,
      data: body,
      options: Options(extra: {'skipAuth': true}),
    );
    return AuthResultModel.fromJson(response.data!);
  }
}
