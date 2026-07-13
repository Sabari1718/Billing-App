import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_security_service.dart';
import 'package:billingapp/mainscreen/utils/api_debug_logger.dart';

class SecurityManager {
  static const double _maxAllowedDistanceMeters = 50000; // 50km allowed area
  static const String _sessionKey = 'user_secure_session';
  static StreamSubscription<Position>? _positionStream;


  /// Validates the current device and location against stored session.
  /// If it fails, returns false and the app should force logout.
  static Future<bool> validateSession(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (!prefs.containsKey(_sessionKey)) {
      if (isLoggedIn) {
        // Reinstalled app or session lost, force re-verification
        _showUnauthorized(context, "Unauthorized Device or Location. Re-verification required.");
        await forceLogout();
        return false;
      }
      return true; // Fresh start, no session yet
    }

    try {
      final String? sessionData = prefs.getString(_sessionKey);
      if (sessionData == null) {
        await ApiDebugLogger.logSessionInfo(
          eventName: 'SESSION_VALIDATION_EVENT',
          sessionStatus: 'INVALID',
        );
        return false;
      }
      
      final storedSession = jsonDecode(sessionData);
      final currentPayload = await DeviceSecurityService.getSecurityPayload();

      // 1. Check Device Change
      if (storedSession['device_id'] != currentPayload['device_id']) {
        _showUnauthorized(context, "Unauthorized Device or Location. App access blocked.");
        await forceLogout();
        await ApiDebugLogger.logSessionInfo(
          eventName: 'SESSION_VALIDATION_EVENT',
          sessionStatus: 'INVALID',
        );
        return false;
      }

      // 2. Check Location Change
      final storedLat = storedSession['latitude'];
      final storedLon = storedSession['longitude'];
      final currentLat = currentPayload['latitude'];
      final currentLon = currentPayload['longitude'];

      if (storedLat != null && storedLon != null && currentLat != null && currentLon != null) {
         final distance = _calculateDistance(storedLat, storedLon, currentLat, currentLon);
         if (distance > _maxAllowedDistanceMeters) {
           _showUnauthorized(context, "Unauthorized Device or Location. Outside allowed area.");
           await forceLogout();
           await ApiDebugLogger.logSessionInfo(
             eventName: 'SESSION_VALIDATION_EVENT',
             sessionStatus: 'INVALID',
           );
           return false;
         }
      }

      // TODO: Call backend validation API with currentPayload
      
      await ApiDebugLogger.logSessionInfo(
        eventName: 'SESSION_VALIDATION_EVENT',
        sessionStatus: 'VALID',
      );
      return true;
    } catch (e) {
      debugPrint("Session validation error: $e");
      await ApiDebugLogger.logSessionInfo(
        eventName: 'SESSION_VALIDATION_EVENT',
        sessionStatus: 'INVALID',
      );
      return false;
    }
  }

  /// Create a new session on login
  static Future<void> createDeviceSession() async {
    final payload = await DeviceSecurityService.getSecurityPayload();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(payload));
    
    // TODO: Call backend to register this device for the user
    // await http.post('/api/register_device', body: payload);
  }

  static Future<void> forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
    await prefs.remove(_sessionKey);
    // Log logout event
    await ApiDebugLogger.logSessionInfo(
      eventName: 'LOGOUT_EVENT',
      sessionStatus: 'INVALID',
    );
  }

  static void _showUnauthorized(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Basic Euclidean distance for mock purposes (Not real Haversine)
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // 1 degree is approx 111 km. This is a very rough mock.
    double dLat = lat1 - lat2;
    double dLon = lon1 - lon2;
    return (dLat * dLat + dLon * dLon) * 111000;
  }

  /// Retrieves headers to attach to every API request
  static Future<Map<String, String>> getSecurityHeaders() async {
    final payload = await DeviceSecurityService.getSecurityPayload();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    
    return {
      'Content-Type': 'application/json',
      'X-Device-ID': payload['device_id'].toString(),
      'X-Location-Lat': payload['latitude']?.toString() ?? '',
      'X-Location-Lon': payload['longitude']?.toString() ?? '',
      'X-Location-Address': payload['readable_address']?.toString() ?? '',
      'Authorization': 'Bearer $token',
    };
  }

  static void startLocationMonitoring(BuildContext context, Function onViolation) {
    _positionStream?.cancel();
    
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Notify every 100 meters
      ),
    ).listen((Position position) async {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_sessionKey)) return;
      
      final String? sessionData = prefs.getString(_sessionKey);
      if (sessionData == null) return;

      final storedSession = jsonDecode(sessionData);
      final storedLat = storedSession['latitude'];
      final storedLon = storedSession['longitude'];
      
      if (storedLat != null && storedLon != null) {
        final distance = _calculateDistance(storedLat, storedLon, position.latitude, position.longitude);
        if (distance > _maxAllowedDistanceMeters) {
          _showUnauthorized(context, "Unauthorized Location. Outside allowed area.");
          await forceLogout();
          onViolation();
        }
      }
    });
  }

  static void stopLocationMonitoring() {
    _positionStream?.cancel();
    _positionStream = null;
  }
}
