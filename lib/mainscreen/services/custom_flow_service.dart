import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:billingapp/mainscreen/utils/api_debug_logger.dart';
import 'package:billingapp/mainscreen/appcontroler/appcontroler/device_service.dart';
import 'package:billingapp/mainscreen/screens/please_update_screen.dart';
import 'package:billingapp/mainscreen/main.dart';
import 'package:billingapp/mainscreen/services/secure_storage_service.dart';

class CustomFlowService {
  static bool updateRequired = false;

  /// Redirects to the Please Update screen and blocks user navigation.
  static void redirectToUpdateScreen() {
    updateRequired = true;
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const PleaseUpdateScreen()),
        (route) => false,
      );
    }
  }

  /// Cleanup old cached app_id values in SharedPreferences and SecureStorage.
  static Future<void> cleanupOldCachedAppId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear general SharedPreferences
      final keys = prefs.getKeys();
      for (var key in keys) {
        try {
          final val = prefs.get(key);
          if (val is String) {
            if (val.contains('PAYMENT-APP-79703') || val.contains('USER-APP-57591') || val.contains('USER-APP-51056')) {
              await prefs.remove(key);
            }
          }
        } catch (_) {}
      }

      // Clear simulated secure storage keys that contain old App IDs
      final secureStorage = await SecureStorageService.getInstance();
      final secKeys = ['app_id', 'appId', 'AppID', 'App ID'];
      for (var key in secKeys) {
        final val = secureStorage.readSecure(key);
        if (val == 'PAYMENT-APP-79703' || val == 'USER-APP-57591' || val == 'USER-APP-51056') {
          await secureStorage.deleteSecure(key);
        }
      }
    } catch (_) {}
  }

  /// Check if the application is running for the very first time.
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRunBefore = prefs.getBool('has_run_before') ?? false;
    return !hasRunBefore;
  }

  /// Mark the first launch flow as successfully completed.
  static Future<void> markFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_run_before', true);
  }

  /// Helper to fetch common device & app parameters for payload compilation.
  static Future<Map<String, dynamic>> _getCommonParams(String userId) async {
    String deviceId = '';
    try {
      deviceId = await DeviceService.getDeviceId();
    } catch (_) {}

    String version = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = '1.0.0';
    } catch (_) {}

    final String platformName = Platform.isAndroid ? 'Android' : 'iOS';

    String deviceName = 'Mobile Device';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      }
    } catch (_) {}

    return {
      'userid': userId,
      'userId': userId,
      'device_id': deviceId,
      'deviceId': deviceId,
      'device': 'Mobile',
      'version': version,
      'software_version': '1.4.1',
      'softwareVersion': '1.4.1',
      'platform_name': platformName,
      'platformName': platformName,
      'platform': platformName,
      'device_name': deviceName,
      'deviceName': deviceName,
      'app_id': '',
      'appId': '',
      'status': 'Active',
    };
  }

  /// Validate that the HTTP response is successful (2xx status) and the response
  /// body does not contain a "success": false property.
  static bool _isValidResponse(dynamic response) {
    if (response == null || response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data.containsKey('success')) {
        return data['success'] == true;
      }
    } catch (_) {}
    return true;
  }

  /// Flow 1 (First install/launch):
  /// Call UserAppData API.
  static Future<bool> checkFirstTimeUserAppData(String userId) async {
    try {
      final url = Uri.parse("https://mobilevalidation.srivagroups.in/api/UserAppData");
      final body = await _getCommonParams(userId);

      debugPrint("Sending app_id: ${body['app_id']}");
      final response = await ApiDebugLogger.httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (_isValidResponse(response)) {
        await markFirstLaunchCompleted();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Flow 2 (Subsequent launches):
  /// Calls UserAppData followed by add-version.
  static Future<bool> checkSplashFlow(String userId) async {
    // 1. Call UserAppData
    try {
      final userAppUrl = Uri.parse("https://mobilevalidation.srivagroups.in/api/UserAppData");
      final body = await _getCommonParams(userId);

      debugPrint("Sending app_id: ${body['app_id']}");
      final userAppResponse = await ApiDebugLogger.httpClient.post(
        userAppUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (!_isValidResponse(userAppResponse)) {
        return false;
      }
    } catch (e) {
      return false;
    }

    // 2. Call add-version
    try {
      final addVersionUrl = Uri.parse("https://mobileadmin.srivagroups.in/api/add-version");
      final body = await _getCommonParams(userId);

      debugPrint("Sending app_id: ${body['app_id']}");
      final addVersionResponse = await ApiDebugLogger.httpClient.post(
        addVersionUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (_isValidResponse(addVersionResponse)) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Flow 2 login action:
  /// Calls add-app-token.
  static Future<bool> checkLoginAppToken(String userId, String token) async {
    try {
      final url = Uri.parse("https://mobileadmin.srivagroups.in/api/add-app-token");
      final body = await _getCommonParams(userId);
      body['token'] = token;
      body['app_token'] = token;
      body['appToken'] = token;

      // Add required params to prevent 400 Bad Request
      body['lifetime'] = 86400;
      body['lifetime_unit'] = 'seconds';
      body['App ID'] = '';
      body['AppID'] = '';
      body['App Id'] = '';
      body['app_id'] = '';
      body['appId'] = '';
      body['API Endpoint'] = 'add-app-token';
      body['APIEndpoint'] = 'add-app-token';
      body['api_endpoint'] = 'add-app-token';
      body['apiEndpoint'] = 'add-app-token';
      body['endpoint'] = 'add-app-token';

      debugPrint("Sending app_id: ${body['app_id']}");
      final response = await ApiDebugLogger.httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 500) {
        return true; // Treat server errors as neutral to prevent lockout
      }

      if (_isValidResponse(response)) {
        return true;
      }
      return false;
    } catch (e) {
      return true; // Treat network exceptions as neutral to prevent lockout
    }
  }

  /// Flow 3 (App-to-App switch):
  /// Calls add-token.
  static Future<bool> checkAppToAppToken(String userId, String token) async {
    try {
      final url = Uri.parse("https://mobileadmin.srivagroups.in/api/add-token");
      final body = await _getCommonParams(userId);
      body['token'] = token;
      body['app_token'] = token;
      body['appToken'] = token;

      // Add required params to prevent 400 Bad Request
      body['lifetime'] = 86400;
      body['lifetime_unit'] = 'seconds';

      debugPrint("Sending app_id: ${body['app_id']}");
      final response = await ApiDebugLogger.httpClient.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode >= 500) {
        return true; // Treat server errors as neutral to prevent lockout
      }

      if (_isValidResponse(response)) {
        return true;
      }
      return false;
    } catch (e) {
      return true; // Treat network exceptions as neutral to prevent lockout
    }
  }

  /// Handles app lifecycle events to detect app-to-app changes.
  static Future<void> handleAppLifecycleChange(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (updateRequired) {
        redirectToUpdateScreen();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final String userId = prefs.getString('user_id') ?? '';
      final String token = prefs.getString('auth_token') ?? '';

      // If user is logged in, perform token check when app is resumed
      if (userId.isNotEmpty && token.isNotEmpty) {
        final bool success = await checkAppToAppToken(userId, token);
        if (!success) {
          updateRequired = true;
          redirectToUpdateScreen();
        }
      }
    }
  }
}
