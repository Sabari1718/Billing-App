import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:billingapp/mainscreen/services/api_service.dart';
import 'package:billingapp/mainscreen/services/secure_storage_service.dart';

class LockRepository {
  final ApiService _apiService;
  final SecureStorageService _secureStorage;

  static const Set<String> backendKeys = {
    'pincode',
    'fingerprint',
    'face_lock',
    'pattern_lock',
    'grid_card',
    'security_tab',
    'mail_otp',
    'whatsapp_otp',
    'sms_otp',
  };

  LockRepository({
    required ApiService apiService,
    required SecureStorageService secureStorage,
  })  : _apiService = apiService,
        _secureStorage = secureStorage;

  Future<Map<String, bool>> fetchLockSettings(int userId) async {
    try {
      debugPrint("========== SECURITY CONSOLE ==========");
      debugPrint("Fetching security settings...");
      debugPrint("API URL: https://lockscreen.srivagroups.in/api/security/update-settings/8227647092");
      final result = await _apiService.request(
        customBaseUrl: 'https://lockscreen.srivagroups.in/api',
        path: '/security/update-settings/8227647092',
        method: 'GET',
      );
      debugPrint("API Response: $result");

      final Map<String, bool> settingsMap = {};
      if (result is Map<String, dynamic> && result.isNotEmpty) {
        bool parseBool(dynamic val) {
          if (val == null) return false;
          if (val is bool) return val;
          final String str = val.toString().toLowerCase().trim();
          return str == 'enable' || str == '1' || str == 'true' || str == 'active';
        }

        final dataMap = result['data'] is Map ? result['data'] : result;
        for (final key in backendKeys) {
          final bool enabled = parseBool(dataMap[key]);
          settingsMap[key] = enabled;
          // Synchronize local secure storage cache with the backend response
          await _secureStorage.writeBoolSecure('enabled_$key', enabled);
        }
        return settingsMap;
      } else {
        // Auto-create settings row on backend with default "disable" values
        debugPrint("========== SECURITY CONSOLE ==========");
        debugPrint("No security settings found. Creating default security settings row...");
        final Map<String, bool> defaultSettings = {};
        for (final key in backendKeys) {
          defaultSettings[key] = false;
        }
        await syncLockSettings(userId, defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      debugPrint("LockRepository: Failed to fetch from backend, relying on local secure cache: $e");
      // Fallback to local secure storage
      final Map<String, bool> cachedSettings = {};
      for (final key in backendKeys) {
        cachedSettings[key] = _secureStorage.readBoolSecure('enabled_$key');
      }
      return cachedSettings;
    }
  }

  /// Updates and synchronizes all lock settings with the backend.
  Future<bool> syncLockSettings(int userId, Map<String, bool> settings) async {
    // Prepare merged payload: merge targeted settings with local secure cache as the source of truth
    final Map<String, String> backendPayload = {};
    for (final key in backendKeys) {
      final bool value = settings.containsKey(key) 
          ? settings[key]! 
          : _secureStorage.readBoolSecure('enabled_$key');
      backendPayload[key] = value ? 'enable' : 'disable';
    }

    final Map<String, dynamic> requestBody = {
      'user_id': userId,
      ...backendPayload,
    };

    try {
      debugPrint("Updating security setting...");
      debugPrint("API URL: https://lockscreen.srivagroups.in/api/security/update-settings/8227647092");
      debugPrint("Request Body: ${jsonEncode(requestBody)}");
      final result = await _apiService.request(
        customBaseUrl: 'https://lockscreen.srivagroups.in/api',
        path: '/security/update-settings/8227647092',
        method: 'POST',
        body: requestBody,
      );
      debugPrint("API Response: $result");

      final bool success = result != null;
      if (success) {
        // Save successfully synchronized states to local secure storage
        for (final key in backendKeys) {
          final bool isEnabled = backendPayload[key] == 'enable';
          await _secureStorage.writeBoolSecure('enabled_$key', isEnabled);
        }
      }
      return success;
    } catch (e) {
      debugPrint("LockRepository: Failed to update lock settings in backend: $e. Writing locally to cache to prevent user blocking.");
      for (final key in backendKeys) {
        final bool isEnabled = backendPayload[key] == 'enable';
        await _secureStorage.writeBoolSecure('enabled_$key', isEnabled);
      }
      return true; // Gracefully continue so user is never blocked by connection failure
    }
  }

  // --- Local Secure Storage Helpers ---
  Future<void> saveLocalConfig(String key, bool enabled, {String? value}) async {
    await _secureStorage.writeBoolSecure('enabled_$key', enabled);
    if (value != null) {
      await _secureStorage.writeSecure('value_$key', value);
    }
  }

  bool getLocalEnabled(String key) {
    return _secureStorage.readBoolSecure('enabled_$key');
  }

  String getLocalValue(String key) {
    return _secureStorage.readSecure('value_$key');
  }

  Future<void> deleteLocalConfig(String key) async {
    await _secureStorage.deleteSecure('enabled_$key');
    await _secureStorage.deleteSecure('value_$key');
    await _secureStorage.deleteSecure('configured_$key');
  }

  Future<void> saveConfiguredState(String key, bool configured) async {
    await _secureStorage.writeBoolSecure('configured_$key', configured);
  }

  bool isLockConfigured(String key) {
    if (key == 'pincode' || key == 'pattern_lock') {
      final String val = getLocalValue(key);
      if (val.isEmpty) return false;
    }
    if (getLocalEnabled(key)) return true;
    return _secureStorage.readBoolSecure('configured_$key');
  }
}
