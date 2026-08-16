import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../core/storage/local_storage.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isAuthenticated = false;
  String? userEmail;
  String? userName;
  String? errorMessage;

  Future<void> checkAuthStatus() async {
    final token = await LocalStorage.getAccessToken();
    if (token != null) {
      isAuthenticated = true;
      await fetchProfile();
    } else {
      isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiConstants.login,
        body: {"email": email, "password": password},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        await LocalStorage.saveTokens(data["access_token"], data["refresh_token"]);
        isAuthenticated = true;
        await fetchProfile();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data["detail"] ?? "Invalid email or password";
      }
    } catch (e) {
      errorMessage = "Connection error. Ensure backend is running.";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> register(String email, String password, String fullName, {String? phone}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiConstants.register,
        body: {
          "email": email,
          "password": password,
          "full_name": fullName,
          "phone_number": phone,
        },
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        await LocalStorage.saveTokens(data["access_token"], data["refresh_token"]);
        isAuthenticated = true;
        await fetchProfile();
        isLoading = false;
        notifyListeners();
        return true;
      } else {
        final data = jsonDecode(res.body);
        errorMessage = data["detail"] ?? "Registration failed";
      }
    } catch (e) {
      errorMessage = "Connection error. Ensure backend is running.";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchProfile() async {
    try {
      final res = await ApiClient.get(ApiConstants.userProfile);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        userEmail = data["email"];
        userName = data["full_name"];
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    try {
      final refreshToken = await LocalStorage.getRefreshToken();
      if (refreshToken != null) {
        await ApiClient.post(ApiConstants.logout, body: {"refresh_token": refreshToken});
      }
    } catch (_) {}

    await LocalStorage.clearSession();
    isAuthenticated = false;
    userEmail = null;
    userName = null;
    notifyListeners();
  }
}
