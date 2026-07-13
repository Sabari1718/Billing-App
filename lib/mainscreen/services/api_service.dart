import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billingapp/mainscreen/config/api_config.dart';
import 'package:billingapp/mainscreen/utils/api_debug_logger.dart';

/// Exception thrown when an API request fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic body;

  ApiException(this.message, {this.statusCode, this.body});

  @override
  String toString() => message;
}

/// Exception thrown when there is no internet connection or socket issues.
class NetworkException extends ApiException {
  NetworkException(super.message);
}

/// Exception thrown when a request times out.
class ApiTimeoutException extends ApiException {
  ApiTimeoutException(super.message);
}

/// Exception thrown when the server returns a 5xx response.
class ServerException extends ApiException {
  ServerException(super.message, int statusCode, dynamic body)
      : super(statusCode: statusCode, body: body);
}

/// Exception thrown when the response cannot be parsed as JSON.
class InvalidResponseException extends ApiException {
  InvalidResponseException(super.message);
}

/// Reusable production-ready API service that uses the Flutter http package with full traceability.
/// Enforced as a Strict Singleton to collapse concurrent requests globally across the application.
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

  String get baseUrl {
    String base = ApiConfig.baseUrl;
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    return base;
  }
  
  // Enforced 15 seconds connect/receive/send timeout limit
  final Duration timeoutDuration = const Duration(seconds: 15);

  // Cache to collapse concurrent duplicate requests in progress
  final Map<String, Future<dynamic>> _inFlightRequests = {};

  // In-memory cache for GET responses to support instant loading
  final Map<String, dynamic> _responseCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheExpiry = const Duration(minutes: 5);

  /// Generates a unique key for each request signature to allow collapsing/deduplicating concurrent requests.
  String _generateRequestKey(String method, String path, dynamic body) {
    final String bodyStr = body != null ? jsonEncode(body) : '';
    return '$method:$path:$bodyStr';
  }

  /// Performs an HTTP request with request debouncing/collapsing, response caching, and custom timeouts.
  Future<dynamic> request({
    required String path,
    required String method,
    Map<String, String>? headers,
    dynamic body,
    String? customBaseUrl,
  }) async {
    final String key = _generateRequestKey(method, path, body);
    final DateTime startTime = DateTime.now();

    // 1. Serve from cache if GET request and cache is fresh
    if (method.toUpperCase() == 'GET' && _responseCache.containsKey(key)) {
      final timestamp = _cacheTimestamps[key];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheExpiry) {
        print("[API DEBUG - DUPLICATE CACHE HIT] Time: $startTime");
        print("Serving cached response for $method $path");
        return _responseCache[key];
      }
    }

    // 2. Collapse concurrent duplicate requests
    if (_inFlightRequests.containsKey(key)) {
      print("[API DEBUG - CONCURRENT COLLAPSE DETECTED] Time: $startTime");
      print("Collapsing duplicate request for $method $path");
      return _inFlightRequests[key]!;
    }

    print("[API DEBUG - START] Method: $method, Path: $path, Time: $startTime");

    final Future<dynamic> future = _executeRequest(
      path: path,
      method: method,
      headers: headers,
      body: body,
      startTime: startTime,
      customBaseUrl: customBaseUrl,
    ).then((result) {
      final DateTime endTime = DateTime.now();
      print("[API DEBUG - SUCCESS] Method: $method, Path: $path, End Time: $endTime, Duration: ${endTime.difference(startTime).inMilliseconds}ms");
      if (method.toUpperCase() == 'GET') {
        _responseCache[key] = result;
        _cacheTimestamps[key] = DateTime.now();
      }
      return result;
    }).catchError((err) {
      final DateTime endTime = DateTime.now();
      print("[API DEBUG - ERROR] Method: $method, Path: $path, End Time: $endTime, Duration: ${endTime.difference(startTime).inMilliseconds}ms, Error: $err");
      throw err;
    }).whenComplete(() {
      _inFlightRequests.remove(key);
    });

    _inFlightRequests[key] = future;
    return future;
  }

  /// Core HTTP network execution logic with strict aborting on timeout
  Future<dynamic> _executeRequest({
    required String path,
    required String method,
    Map<String, String>? headers,
    dynamic body,
    required DateTime startTime,
    String? customBaseUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token == null || token.isEmpty) {
      print("ApiService WARNING: TOKEN IS EMPTY");
    }

    String cleanPath = path;
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    
    String activeBase;
    if (customBaseUrl != null) {
      activeBase = customBaseUrl.endsWith('/') 
          ? customBaseUrl.substring(0, customBaseUrl.length - 1) 
          : customBaseUrl;
    } else {
      activeBase = baseUrl;
    }

    if (cleanPath.contains('/security/update-settings')) {
      activeBase = 'https://lockscreen.srivagroups.in/api';
      cleanPath = '/security/update-settings/8227647092';
    }

    final Uri uri = Uri.parse('$activeBase$cleanPath');
    
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    // Max 1 retry only (meaning maximum 2 attempts for GET requests, and 1 for modification requests)
    final int maxAttempts = (method.toUpperCase() == 'GET') ? 2 : 1;
    const Duration retryDelay = Duration(milliseconds: 100); // 100ms only! Very fast fail!

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      final client = ApiDebugLogger.wrapClient(http.Client());
      try {
        final Future<http.Response> responseFuture;
        
        switch (method.toUpperCase()) {
          case 'GET':
            responseFuture = client.get(uri, headers: requestHeaders);
            break;
          case 'POST':
            responseFuture = client.post(
              uri, 
              headers: requestHeaders, 
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'PUT':
            responseFuture = client.put(
              uri, 
              headers: requestHeaders, 
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          case 'DELETE':
            responseFuture = client.delete(
              uri, 
              headers: requestHeaders, 
              body: body != null ? jsonEncode(body) : null,
            );
            break;
          default:
            throw ApiException('Unsupported HTTP method: $method');
        }

        final response = await responseFuture.timeout(timeoutDuration, onTimeout: () {
          client.close(); // Forcefully abort network socket instantly to prevent hanging futures
          throw TimeoutException('Request timed out after ${timeoutDuration.inSeconds} seconds');
        });

        return _handleResponse(response);
      } on SocketException catch (e) {
        print("[API DEBUG - SOCKET EXCEPTION] Attempt $attempt failed: ${e.message}");
        client.close();
        if (attempt >= maxAttempts) {
          throw NetworkException(
            'Server Unreachable: Connection failed. Please verify that the Node.js backend is running properly.'
          );
        }
        await Future.delayed(retryDelay);
      } on TimeoutException catch (e) {
        final DateTime errorTime = DateTime.now();
        print("[API DEBUG - TIMEOUT SOURCE] Attempt $attempt failed. Timeout Duration: ${errorTime.difference(startTime).inSeconds}s, Error: $e");
        client.close();
        if (attempt >= maxAttempts) {
          throw ApiTimeoutException(
            'Connection Timeout: The server took too long to respond.'
          );
        }
        await Future.delayed(retryDelay);
      } catch (e) {
        print("[API DEBUG - GENERIC FAILURE] Attempt $attempt failed: $e");
        client.close();
        if (attempt >= maxAttempts) {
          if (e is ApiException) {
            rethrow;
          }
          throw ApiException('Communication error occurred: $e');
        }
        await Future.delayed(retryDelay);
      }
    }

    throw ApiException('Request failed to complete after $maxAttempts attempts');
  }

  dynamic _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    
    dynamic responseBody;
    if (response.body.isNotEmpty) {
      try {
        responseBody = jsonDecode(response.body);
      } catch (e) {
        throw InvalidResponseException('Malformed Response: The backend returned an invalid JSON schema.');
      }
    }

    if (statusCode >= 200 && statusCode < 300) {
      return responseBody;
    } else if (statusCode >= 500) {
      throw ServerException(
        'Server Error: Node.js backend encountered a critical error (Status $statusCode).',
        statusCode,
        responseBody,
      );
    } else {
      final String errorMessage = responseBody != null && responseBody['message'] != null
          ? responseBody['message'].toString()
          : (responseBody != null && responseBody['error'] != null 
              ? responseBody['error'].toString()
              : 'Action failed: Server returned code $statusCode');
      throw ApiException(errorMessage, statusCode: statusCode, body: responseBody);
    }
  }
}
