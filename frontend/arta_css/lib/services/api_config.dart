import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// API configuration for connecting to the backend server
/// The backend handles all Firebase/Firestore operations server-side
class ApiConfig {
  // Production backend URL (Vercel deployment)
  static const String _defaultBaseUrl = 'https://backend-one-murex-34.vercel.app';
  
  // Storage key for custom backend URL
  static const String _baseUrlKey = 'backend_base_url';
  
  // Cached base URL
  static String? _cachedBaseUrl;
  
  /// Get the current backend base URL
  static Future<String> getBaseUrl() async {
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedBaseUrl = prefs.getString(_baseUrlKey) ?? _defaultBaseUrl;
    } catch (e) {
      _cachedBaseUrl = _defaultBaseUrl;
    }
    
    return _cachedBaseUrl!;
  }
  
  /// Set a custom backend URL (useful for development/testing)
  static Future<void> setBaseUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_baseUrlKey, url);
      _cachedBaseUrl = url;
      if (kDebugMode) debugPrint('ApiConfig: Base URL set to $url');
    } catch (e) {
      if (kDebugMode) debugPrint('ApiConfig: Error setting base URL: $e');
    }
  }
  
  /// Reset to default URL
  static Future<void> resetBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_baseUrlKey);
      _cachedBaseUrl = _defaultBaseUrl;
    } catch (e) {
      if (kDebugMode) debugPrint('ApiConfig: Error resetting base URL: $e');
    }
  }
  
  /// Default timeout for API requests
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Default headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

/// HTTP client wrapper with common functionality
class ApiClient {
  final http.Client _client;
  
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  
  /// Make a GET request
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      var uri = Uri.parse('$baseUrl$endpoint');
      
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      
      if (kDebugMode) debugPrint('API GET: $uri');
      
      final response = await _client
          .get(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('API GET Error: $e');
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Make a POST request
  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) debugPrint('API POST: $uri');
      
      final response = await _client
          .post(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.defaultTimeout);
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('API POST Error: $e');
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Make a PUT request
  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) debugPrint('API PUT: $uri');
      
      final response = await _client
          .put(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.defaultTimeout);
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('API PUT Error: $e');
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Make a PATCH request
  Future<ApiResponse> patch(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) debugPrint('API PATCH: $uri');
      
      final response = await _client
          .patch(
            uri,
            headers: ApiConfig.defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.defaultTimeout);
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('API PATCH Error: $e');
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Make a DELETE request
  Future<ApiResponse> delete(String endpoint) async {
    try {
      final baseUrl = await ApiConfig.getBaseUrl();
      final uri = Uri.parse('$baseUrl$endpoint');
      
      if (kDebugMode) debugPrint('API DELETE: $uri');
      
      final response = await _client
          .delete(uri, headers: ApiConfig.defaultHeaders)
          .timeout(ApiConfig.defaultTimeout);
      
      return ApiResponse.fromHttpResponse(response);
    } catch (e) {
      if (kDebugMode) debugPrint('API DELETE Error: $e');
      return ApiResponse.error(e.toString());
    }
  }
  
  /// Check if the backend is reachable
  Future<bool> ping() async {
    try {
      final response = await get('/ping');
      return response.isSuccess && response.data?['ok'] == true;
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    _client.close();
  }
}

/// Wrapper for API responses
class ApiResponse {
  final int statusCode;
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;
  
  ApiResponse({
    required this.statusCode,
    required this.isSuccess,
    this.data,
    this.error,
  });
  
  factory ApiResponse.fromHttpResponse(http.Response response) {
    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
    Map<String, dynamic>? data;
    String? error;
    
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
          if (!isSuccess) {
            error = data['error']?.toString() ?? 'Unknown error';
          }
        }
      }
    } catch (e) {
      error = 'Failed to parse response: $e';
    }
    
    return ApiResponse(
      statusCode: response.statusCode,
      isSuccess: isSuccess,
      data: data,
      error: error,
    );
  }
  
  factory ApiResponse.error(String message) {
    return ApiResponse(
      statusCode: 0,
      isSuccess: false,
      error: message,
    );
  }
}
