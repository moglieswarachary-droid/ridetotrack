import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const String _tokenKey = "ridetrack_access_token";
  static const String _refreshTokenKey = "ridetrack_refresh_token";
  static const String _userKey = "ridetrack_user_data";
  static const String _unitSystemKey = "ridetrack_unit_system";
  static const String _trackingQualityKey = "ridetrack_tracking_quality";

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  static Future<void> setTrackingQuality(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trackingQualityKey, mode);
  }

  static Future<String> getTrackingQuality() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_trackingQualityKey) ?? "balanced";
  }
}
