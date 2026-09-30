final class AuthResultModel {
  const AuthResultModel({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthResultModel.fromJson(Map<String, dynamic> json) {
    return AuthResultModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: json['user_id'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final String userId;
}
