import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/mainscreen/services/secure_storage_service.dart';

/// Centralized API Debug Logger for intercepting and logging API calls, errors, and session details.
class ApiDebugLogger {
  // Reusable logged HttpClient instance for static HTTP calls
  static final http.Client httpClient = LoggingHttpClient(http.Client());

  // Dio Interceptor instance
  static final Interceptor dioInterceptor = ApiDebugInterceptor();

  /// Wraps an existing http.Client to intercept and log all of its requests and responses.
  static http.Client wrapClient(http.Client client) {
    return LoggingHttpClient(client);
  }

  /// Print Request details in a clear formatted layout
  static void logRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    required dynamic body,
  }) {
    if (!kDebugMode) return;
    print("Sending app_id: ");
    final String timestamp = DateTime.now().toString();
    print('================ API REQUEST ================');
    print('URL      : $url');
    print('METHOD   : ${method.toUpperCase()}');
    print('HEADERS  : $headers');
    print('BODY     : ${_stringifyBody(body)}');
    print('TIME     : $timestamp');
    print('===========================================');
  }

  /// Print Response details in a clear formatted layout
  static void logResponse({
    required String url,
    required int statusCode,
    required dynamic responseBody,
    required Map<String, String> headers,
    required Duration? duration,
  }) {
    if (!kDebugMode) return;
    final int durationMs = duration?.inMilliseconds ?? 0;
    print('================ API RESPONSE ===============');
    print('URL      : $url');
    print('STATUS   : $statusCode');
    print('DURATION : $durationMs ms');
    print('BODY     : ${_stringifyBody(responseBody)}');
    print('==========================================');
  }

  /// Print Error details in a clear formatted layout
  static void logError({
    required String url,
    required int? statusCode,
    required String message,
    required dynamic errorResponse,
    required StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    print('================ API ERROR ==================');
    print('URL      : $url');
    print('STATUS   : ${statusCode ?? "N/A"}');
    print('MESSAGE  : $message');
    print('RESPONSE : ${_stringifyBody(errorResponse)}');
    if (stackTrace != null) {
      print('STACK TRACE:\n$stackTrace');
    }
    print('=============================================');
  }

  /// Print Session information details in a clear formatted layout
  static Future<void> logSessionInfo({
    String? eventName,
    String? sessionStatus,
  }) async {
    if (!kDebugMode) return;

    try {
      final secureStorage = await SecureStorageService.getInstance();
      final prefs = await SharedPreferences.getInstance();

      // Retrieve User ID
      String userId = secureStorage.readSecure('userid');
      if (userId.isEmpty) {
        userId = prefs.getString('user_id') ?? prefs.getInt('auth_id')?.toString() ?? 'N/A';
      }

      // Retrieve Device ID
      String deviceId = secureStorage.readSecure('device_id');
      if (deviceId.isEmpty) {
        deviceId = prefs.getString('user_device_id') ?? 'N/A';
      }

      // Retrieve App Name
      String appName = secureStorage.readSecure('app_name');
      if (appName.isEmpty) {
        appName = 'Circuit Point';
      }

      // Retrieve App Version
      String appVersion = secureStorage.readSecure('version');
      if (appVersion.isEmpty) {
        appVersion = '1.0.0';
      }

      // Retrieve Software Version
      String softwareVersion = secureStorage.readSecure('software_version');
      if (softwareVersion.isEmpty) {
        softwareVersion = '1.4.1';
      }

      // Login status check
      final bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final String loginStatus = isLoggedIn ? 'LOGGED_IN' : 'LOGGED_OUT';

      // Computed Session Status
      final String computedSessionStatus = sessionStatus ?? (isLoggedIn ? 'VALID' : 'INVALID');

      print('==================== SESSION INFO ===================');
      if (eventName != null) {
        print('EVENT: $eventName');
      }
      print('USER ID: $userId');
      print('DEVICE ID: $deviceId');
      print('APP NAME: $appName');
      print('APP VERSION: $appVersion');
      print('SOFTWARE VERSION: $softwareVersion');
      print('LOGIN STATUS: $loginStatus');
      print('SESSION STATUS: $computedSessionStatus');
      print('========================================================');
    } catch (e) {
      print('Error logging session info: $e');
    }
  }

  // Private helper to stringify payloads cleanly
  static String _stringifyBody(dynamic body) {
    if (body == null) return 'null';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }
}

/// Custom client that logs standard HTTP calls automatically using ApiDebugLogger.
class LoggingHttpClient extends http.BaseClient {
  final http.Client _inner;
  LoggingHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final startTime = DateTime.now();

    dynamic requestBody;
    if (request is http.Request) {
      requestBody = request.body;
    } else {
      requestBody = "streamed body";
    }

    ApiDebugLogger.logRequest(
      method: request.method,
      url: request.url.toString(),
      headers: request.headers,
      body: requestBody,
    );

    try {
      final streamedResponse = await _inner.send(request);
      final bytes = await streamedResponse.stream.toBytes();
      final responseBodyString = utf8.decode(bytes, allowMalformed: true);
      final endTime = DateTime.now();

      if (streamedResponse.statusCode >= 400) {
        ApiDebugLogger.logError(
          url: request.url.toString(),
          statusCode: streamedResponse.statusCode,
          message: streamedResponse.reasonPhrase ?? "HTTP Error ${streamedResponse.statusCode}",
          errorResponse: responseBodyString,
          stackTrace: null,
        );
      } else {
        ApiDebugLogger.logResponse(
          url: request.url.toString(),
          statusCode: streamedResponse.statusCode,
          responseBody: responseBodyString,
          headers: streamedResponse.headers,
          duration: endTime.difference(startTime),
        );
      }

      return http.StreamedResponse(
        Stream.value(bytes),
        streamedResponse.statusCode,
        contentLength: streamedResponse.contentLength,
        request: request,
        headers: streamedResponse.headers,
        isRedirect: streamedResponse.isRedirect,
        persistentConnection: streamedResponse.persistentConnection,
        reasonPhrase: streamedResponse.reasonPhrase,
      );
    } catch (e, stackTrace) {
      ApiDebugLogger.logError(
        url: request.url.toString(),
        statusCode: null,
        message: e.toString(),
        errorResponse: null,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}

/// Custom interceptor that logs Dio calls automatically using ApiDebugLogger.
class ApiDebugInterceptor extends Interceptor {
  final Map<RequestOptions, DateTime> _startTimes = {};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _startTimes[options] = DateTime.now();
    ApiDebugLogger.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers.map((k, v) => MapEntry(k, v.toString())),
      body: options.data,
    );
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = _startTimes.remove(response.requestOptions);
    final duration = startTime != null ? DateTime.now().difference(startTime) : null;
    
    if (response.statusCode != null && response.statusCode! >= 400) {
      ApiDebugLogger.logError(
        url: response.requestOptions.uri.toString(),
        statusCode: response.statusCode,
        message: response.statusMessage ?? "HTTP Error ${response.statusCode}",
        errorResponse: response.data,
        stackTrace: null,
      );
    } else {
      ApiDebugLogger.logResponse(
        url: response.requestOptions.uri.toString(),
        statusCode: response.statusCode ?? 0,
        responseBody: response.data,
        headers: response.headers.map.map((k, v) => MapEntry(k, v.join(', '))),
        duration: duration,
      );
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _startTimes.remove(err.requestOptions);

    ApiDebugLogger.logError(
      url: err.requestOptions.uri.toString(),
      statusCode: err.response?.statusCode,
      message: err.message ?? err.toString(),
      errorResponse: err.response?.data,
      stackTrace: err.stackTrace,
    );
    super.onError(err, handler);
  }
}
