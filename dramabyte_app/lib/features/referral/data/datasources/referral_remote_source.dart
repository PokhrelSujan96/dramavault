import 'package:dramabyte_app/core/network/api_client.dart';
import 'package:dramabyte_app/features/referral/data/models/referral_summary_model.dart';

final class ReferralRemoteSource {
  ReferralRemoteSource(this._client);

  final ApiClient _client;

  Future<ReferralSummaryModel> summary() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/referral/me',
    );
    return ReferralSummaryModel(response.data ?? const {});
  }
}
