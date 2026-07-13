import 'package:billingapp/mainscreen/services/api_service.dart';

/// Service responsible for managing user Two-Step Authentication configurations on the backend with full debugging.
class TwoStepAuthService {
  final ApiService _apiService;

  TwoStepAuthService(this._apiService);

  /// Updates the user's active two-step locks and OTP configurations on the Node.js backend.
  /// 
  /// Path: PUT /two-step-authentication/update
  Future<Map<String, dynamic>> updateTwoStepAuth({
    required int userId,
    required bool gridCard,
    required bool securityTab,
    required bool mailOtp,
    required bool whatsappOtp,
    required bool smsOtp,
    required bool fingerprint,
    required bool faceLock,
    required bool patternLock,
    required String pincode,
  }) async {
    // Extensive debug logging of all 9 parameters exactly as required
    print("========== UPDATE TWO STEP AUTH ==========");
    print("User ID: $userId");
    print("MFA Grid Card lock active: $gridCard");
    print("MFA Security Tab lock active: $securityTab");
    print("MFA Mail OTP lock active: $mailOtp");
    print("MFA WhatsApp OTP lock active: $whatsappOtp");
    print("MFA SMS OTP lock active: $smsOtp");
    print("MFA Fingerprint lock active: $fingerprint");
    print("MFA Face Lock lock active: $faceLock");
    print("MFA Pattern Lock lock active: $patternLock");
    print("MFA Pincode configured: $pincode");

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      'grid_card': gridCard ? 1 : 0,
      'security_tab': securityTab ? 1 : 0,
      'mail_otp': mailOtp ? 1 : 0,
      'whatsapp_otp': whatsappOtp ? 1 : 0,
      'sms_otp': smsOtp ? 1 : 0,
      'fingerprint': fingerprint ? 1 : 0,
      'face_lock': faceLock ? 1 : 0,
      'pattern_lock': patternLock ? 1 : 0,
      'pincode': pincode,
    };

    try {
      final result = await _apiService.request(
        path: '/two-step-authentication/update',
        method: 'PUT',
        body: requestBody,
      );

      print("Update Two-Step Authentication API success");
      return result is Map<String, dynamic> ? result : {'success': true};
    } catch (e, stackTrace) {
      print("========== EXCEPTION (Update Two-Step Auth) ==========");
      print("ERROR: $e");
      print("STACKTRACE:");
      print(stackTrace);
      rethrow;
    }
  }

  /// Retrieves user's security settings from the backend.
  /// 
  /// Path: GET /security/update-settings/:user_id
  Future<Map<String, dynamic>> getSecuritySettings(int userId) async {
    try {
      final result = await _apiService.request(
        customBaseUrl: 'https://lockscreen.srivagroups.in/api',
        path: '/security/update-settings/8227647092',
        method: 'GET',
      );
      print("Get Security Settings API success: $result");
      return result is Map<String, dynamic> ? result : {};
    } catch (e, stackTrace) {
      print("========== EXCEPTION (Get Security Settings) ==========");
      print("ERROR: $e");
      print("STACKTRACE:");
      print(stackTrace);
      rethrow;
    }
  }

  /// Updates the user's security settings on the backend using the enable/disable format.
  /// 
  /// Path: POST /security/update-settings
  Future<Map<String, dynamic>> updateSecuritySettings({
    required int userId,
    required bool fingerprint,
    required bool faceLock,
    required bool patternLock,
    required bool pincode,
    required bool gridCard,
    required bool securityTab,
    required bool mailOtp,
    required bool whatsappOtp,
    required bool smsOtp,
  }) async {
    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      'fingerprint': fingerprint ? 'enable' : 'disable',
      'face_lock': faceLock ? 'enable' : 'disable',
      'pattern_lock': patternLock ? 'enable' : 'disable',
      'pincode': pincode ? 'enable' : 'disable',
      'grid_card': gridCard ? 'enable' : 'disable',
      'security_tab': securityTab ? 'enable' : 'disable',
      'mail_otp': mailOtp ? 'enable' : 'disable',
      'whatsapp_otp': whatsappOtp ? 'enable' : 'disable',
      'sms_otp': smsOtp ? 'enable' : 'disable',
    };

    print("========== UPDATE SECURITY SETTINGS (enable/disable format) ==========");
    print("Request Body: $requestBody");

    try {
      final result = await _apiService.request(
        customBaseUrl: 'https://lockscreen.srivagroups.in/api',
        path: '/security/update-settings/8227647092',
        method: 'POST',
        body: requestBody,
      );
      print("Update Security Settings API success");
      return result is Map<String, dynamic> ? result : {'success': true};
    } catch (e, stackTrace) {
      print("========== EXCEPTION (Update Security Settings) ==========");
      print("ERROR: $e");
      print("STACKTRACE:");
      print(stackTrace);
      rethrow;
    }
  }
}
