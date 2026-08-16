import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../storage/local_storage.dart';

class ApiClient {
  static String baseUrl = ApiConstants.localhostBaseUrl;

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

    final response = await http.get(uri, headers: _buildHeaders(token));
    if (response.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await LocalStorage.getAccessToken();
        return await http.get(uri, headers: _buildHeaders(newToken));
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
    );

    if (response.statusCode == 401 && !endpoint.contains("/auth/")) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final newToken = await LocalStorage.getAccessToken();
        return await http.post(
          uri,
          headers: _buildHeaders(newToken),
          body: body != null ? jsonEncode(body) : null,
        );
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
    );
    return response;
  }

  static Future<http.Response> delete(String endpoint) async {
    final token = await LocalStorage.getAccessToken();
    final uri = Uri.parse("$baseUrl$endpoint");

    return await http.delete(uri, headers: _buildHeaders(token));
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
      );

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
