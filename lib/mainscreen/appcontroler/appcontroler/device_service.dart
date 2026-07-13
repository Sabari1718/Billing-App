import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:billingapp/mainscreen/utils/api_debug_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'api_config.dart';

class DeviceService {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static const String _deviceIdKey = 'stored_device_id';

  static Future<String> getDeviceId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check if device ID is already persisted
      String? storedDeviceId = prefs.getString(_deviceIdKey);
      if (storedDeviceId != null && storedDeviceId.trim().isNotEmpty && storedDeviceId.toLowerCase() != "unknown") {
        return storedDeviceId;
      }

      String? newDeviceId;

      // 2. Try to get hardware device ID
      try {
        if (Platform.isAndroid) {
          AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
          newDeviceId = androidInfo.id;
        } else if (Platform.isIOS) {
          IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
          newDeviceId = iosInfo.identifierForVendor;
        }
      } catch (e) {
        print("Error getting hardware device ID: $e");
      }

      // 3. Validate retrieved ID or generate fallback UUID
      if (newDeviceId == null || newDeviceId.trim().isEmpty || newDeviceId.toLowerCase() == "unknown") {
        newDeviceId = const Uuid().v4();
        print("Using fallback UUID for device ID: $newDeviceId");
      } else {
        if (Platform.isAndroid) {
          newDeviceId = "ANDROID_$newDeviceId";
        } else if (Platform.isIOS) {
          newDeviceId = "IOS_$newDeviceId";
        }
      }

      // 4. Persist the generated/retrieved device ID
      await prefs.setString(_deviceIdKey, newDeviceId);
      return newDeviceId;

    } catch (e) {
      print("Critical error in getDeviceId: $e");
      // Fallback if SharedPreferences fails
      return const Uuid().v4();
    }
  }

  static Future<bool> sendDeviceIdToBackend(String deviceId) async {
    final url = Uri.parse(ApiConfig.deviceStore);
    final prefs = await SharedPreferences.getInstance();
    
    String userId = prefs.getString('user_id') ?? '';
    String appName = 'Billing App';
    String version = '1.0.0';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      version = '1.0.0';
      appName = 'Billing App';
    } catch (_) {}
    
    const String softwareVersion = '1.4.1';

    final body = {
      "userid": userId,
      "device_id": deviceId,
      "app_name": appName,
      "version": version,
      "software_version": softwareVersion
    };

    try {
      final response = await ApiDebugLogger.httpClient.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
