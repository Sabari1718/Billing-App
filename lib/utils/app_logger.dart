import 'package:flutter/foundation.dart';

class AppLogger {
  static bool get _isDebug => kDebugMode;

  static void info(String message) {
    if (_isDebug) {
      debugPrint('📘 [INFO]: $message');
    }
  }

  static void success(String message) {
    if (_isDebug) {
      debugPrint('✅ [SUCCESS]: $message');
    }
  }

  static void warning(String message) {
    if (_isDebug) {
      debugPrint('⚠️ [WARNING]: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    // Error logs might be useful even in production for crash reporting, 
    // but here we keep it simple.
    debugPrint('❌ [ERROR]: $message');
    if (error != null) debugPrint('Details: $error');
    if (stackTrace != null && _isDebug) debugPrint('StackTrace: $stackTrace');
  }

  static void api(String method, String url, int statusCode, {String? body, bool isError = false}) {
    if (_isDebug || isError || statusCode >= 400) {
      final String tag = (statusCode >= 200 && statusCode < 300) ? '🌐 [API SUCCESS]' : '🚫 [API ERROR]';
      debugPrint('$tag: $method $url ($statusCode)');
      if (isError && body != null) {
        debugPrint('Response Body: $body');
      }
    }
  }
  
  static void debug(String message) {
    if (_isDebug) {
      debugPrint('🔍 [DEBUG]: $message');
    }
  }
}
