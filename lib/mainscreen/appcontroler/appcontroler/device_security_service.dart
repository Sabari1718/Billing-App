import 'dart:io';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'device_service.dart';

class DeviceSecurityService {
  /// Retrieves a comprehensive security payload used for device verification.
  /// If [fetchLocation] is true, attempts to get current GPS coordinates and a
  /// readable address. Otherwise latitude, longitude and address are null.
  static Future<Map<String, dynamic>> getSecurityPayload({bool fetchLocation = true}) async {
    // Device ID
    final String deviceId = await DeviceService.getDeviceId();

    // Device model placeholder (can be extended later)
    String deviceModel = 'unknown';
    try {
      if (Platform.isAndroid) {
        // For simplicity, we use deviceId as model placeholder on Android.
        deviceModel = deviceId;
      } else if (Platform.isIOS) {
        deviceModel = deviceId;
      }
    } catch (_) {}

    // App version
    String appVersion = 'unknown';
    try {
      final pkgInfo = await PackageInfo.fromPlatform();
      appVersion = pkgInfo.version;
    } catch (_) {}

    // Location (optional)
    double? latitude;
    double? longitude;
    String? readableAddress;
    if (fetchLocation) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await Permission.location.status;
          if (!permission.isGranted) {
            permission = await Permission.location.request();
          }
          if (permission.isGranted) {
            final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
            );
            latitude = position.latitude;
            longitude = position.longitude;
            // Simple address placeholder – real reverse‑geocoding can be added later.
            readableAddress = 'Location captured';
          }
        }
      } catch (_) {}
    }

    return {
      'device_id': deviceId,
      'device_model': deviceModel,
      'platform': Platform.operatingSystem,
      'version': appVersion,
      'latitude': latitude,
      'longitude': longitude,
      'readable_address': readableAddress,
      'sim_info': [], // Not implemented in this minimal version
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
