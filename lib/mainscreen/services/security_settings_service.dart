import 'package:billingapp/mainscreen/services/api_service.dart';

class SecuritySettingsService {
  final ApiService _apiService;

  SecuritySettingsService(this._apiService);

  Future<Map<String, dynamic>> getSecuritySettings(int userId) async {
    final result = await _apiService.request(
      customBaseUrl: 'https://lockscreen.srivagroups.in/api',
      path: '/security/update-settings/8227647092',
      method: 'GET',
    );
    return result is Map<String, dynamic> ? result : {};
  }

  Future<Map<String, dynamic>> updateSecuritySetting({
    required int userId,
    required Map<String, String> backendPayload,
  }) async {
    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      ...backendPayload,
    };
    final result = await _apiService.request(
      customBaseUrl: 'https://lockscreen.srivagroups.in/api',
      path: '/security/update-settings/8227647092',
      method: 'POST',
      body: requestBody,
    );
    return result is Map<String, dynamic> ? result : {};
  }
}
