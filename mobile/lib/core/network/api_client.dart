import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static String baseUrl = ApiConstants.getDefaultBaseUrl();

  /// Gets the WebSocket base URL matching the current active HTTP baseUrl.
  static String get wsBaseUrl => ApiConstants.getWsUrlFromBaseUrl(baseUrl);

  /// Initializes the client with saved custom URL if present, or platform defaults.
  static Future<void> initialize() async {
    try {
      final savedUrl = await LocalStorage.getServerBaseUrl();
      if (savedUrl != null && savedUrl.isNotEmpty) {
        baseUrl = savedUrl;
      } else {
        baseUrl = ApiConstants.getDefaultBaseUrl();
      }
      debugPrint("[ApiClient] Initialized with baseUrl: $baseUrl (WS: $wsBaseUrl)");
    } catch (e) {
      baseUrl = ApiConstants.getDefaultBaseUrl();
    }
  }

  /// Manually override the active Base URL at runtime and persist it.
  static Future<void> setBaseUrl(String newUrl) async {
    var formatted = newUrl.trim();
    if (formatted.endsWith("/")) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    // Ensure /api/v1 suffix if missing
    if (!formatted.endsWith("/api/v1") && !formatted.contains("/api/")) {
      formatted = "$formatted/api/v1";
    }
    baseUrl = formatted;
    await LocalStorage.setServerBaseUrl(formatted);
    debugPrint("[ApiClient] BaseUrl updated to: $baseUrl (WS: $wsBaseUrl)");
  }

  /// Reset base URL to the platform default
  static Future<void> resetBaseUrl() async {
    await LocalStorage.clearServerBaseUrl();
    baseUrl = ApiConstants.getDefaultBaseUrl();
    debugPrint("[ApiClient] BaseUrl reset to platform default: $baseUrl");
  }

  /// Tests connectivity to a specific or current server URL.
  static Future<bool> testConnection([String? targetUrl]) async {
    final testUrl = targetUrl ?? baseUrl;
    try {
      // Form health check URI by checking /health at root or direct URL
      Uri healthUri;
      if (testUrl.contains("/api/v1")) {
        final rootUrl = testUrl.replaceAll("/api/v1", "");
        healthUri = Uri.parse("$rootUrl/health");
      } else {
        healthUri = Uri.parse("$testUrl/health");
      }

      final res = await http.get(healthUri).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      // Try testing the baseUrl directly
      try {
        final directUri = Uri.parse(testUrl);
        final res = await http.get(directUri).timeout(const Duration(seconds: 4));
        return res.statusCode < 500;
      } catch (_) {
        return false;
      }
    }
  }

  static Map<String, String> _buildHeaders(String? token) {
    final headers = {
      HttpHeaders.contentTypeHeader: "application/json",
      HttpHeaders.acceptHeader: "application/json",
    };
    if (token != null) {
      headers[HttpHeaders.authorizationHeader] = "Bearer $token";
    }
    return headers;
  }

  static Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final token = await LocalStorage.getAccessToken();
    var uri = Uri.parse("$baseUrl$endpoint");
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final response = await http.get(uri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 10));
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await LocalStorage.getAccessToken();
        return await http.get(uri, headers: _buildHeaders(newToken)).timeout(const Duration(seconds: 10));
      }
    }
    return response;
  }

  static Future<http.Response> post(String endpoint, {dynamic body}) async {
    final token = await LocalStorage.getAccessToken();
    final uri = Uri.parse("$baseUrl$endpoint");

    final response = await http.post(
      uri,
      headers: _buildHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 401 && !endpoint.contains("/auth/")) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await LocalStorage.getAccessToken();
        return await http.post(
          uri,
          headers: _buildHeaders(newToken),
          body: body != null ? jsonEncode(body) : null,
        ).timeout(const Duration(seconds: 10));
      }
    }
    return response;
  }

  static Future<http.Response> put(String endpoint, {dynamic body}) async {
    final token = await LocalStorage.getAccessToken();
    final uri = Uri.parse("$baseUrl$endpoint");

    final response = await http.put(
      uri,
      headers: _buildHeaders(token),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 10));
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final token = await LocalStorage.getAccessToken();
    final uri = Uri.parse("$baseUrl$endpoint");

    return await http.delete(uri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 10));
  }

  static Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken == null) return false;

      final uri = Uri.parse("$baseUrl${ApiConstants.refresh}");
      final res = await http.post(
        uri,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: jsonEncode({"refresh_token": refreshToken}),
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await LocalStorage.saveTokens(data["access_token"], data["refresh_token"]);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
