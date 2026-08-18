import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  // Compile-time environment overrides (e.g. flutter run --dart-define=API_URL=http://192.168.1.50:8000/api/v1)
  static const String envApiUrl = String.fromEnvironment('API_URL');
  static const String envWsUrl = String.fromEnvironment('WS_URL');

  // Hosted Production URLs (Railway)
  static const String productionBaseUrl = "https://ridetotrack-production.up.railway.app/api/v1";
  static const String productionWsUrl = "wss://ridetotrack-production.up.railway.app/api/v1";

  // Local Development Fallbacks
  static const String emulatorBaseUrl = "http://10.0.2.2:8000/api/v1";
  static const String localhostBaseUrl = "http://127.0.0.1:8000/api/v1";

  /// Resolves the most appropriate default base URL based on platform & environment.
  static String getDefaultBaseUrl() {
    if (envApiUrl.isNotEmpty) {
      return envApiUrl;
    }
    if (kReleaseMode) {
      return productionBaseUrl;
    }
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Android emulator loopback alias to host machine
        return emulatorBaseUrl;
      }
    } catch (_) {
      // Fallback for environments where Platform is not supported
    }
    return localhostBaseUrl;
  }

  /// Dynamically computes the WebSocket URL from an HTTP(S) API base URL.
  static String getWsUrlFromBaseUrl(String httpBaseUrl) {
    if (envWsUrl.isNotEmpty && httpBaseUrl == getDefaultBaseUrl()) {
      return envWsUrl;
    }
    if (httpBaseUrl.startsWith("https://")) {
      return httpBaseUrl.replaceFirst("https://", "wss://");
    } else if (httpBaseUrl.startsWith("http://")) {
      return httpBaseUrl.replaceFirst("http://", "ws://");
    }
    return "ws://$httpBaseUrl";
  }

  // Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String refresh = "/auth/refresh";
  static const String logout = "/auth/logout";
  static const String userProfile = "/users/me";

  static const String bikes = "/bikes";
  static const String trackingStart = "/tracking/start";
  static const String trackingActive = "/tracking/active";
  static const String trackingLocations = "/tracking/{id}/locations";
  static const String trackingPause = "/tracking/{id}/pause";
  static const String trackingResume = "/tracking/{id}/resume";
  static const String trackingStop = "/tracking/{id}/stop";
  static const String trackingLive = "/tracking/{id}/live";

  static const String rides = "/rides";
  static const String parking = "/parking";
  static const String parkingCurrent = "/parking/current";
  static const String parkingDirections = "/parking/directions";
  static const String geofences = "/geofences";
  static const String alerts = "/alerts";
  static const String crashReport = "/alerts/crash-report";
  static const String emergencyContacts = "/emergency-contacts";
  static const String sosBroadcast = "/emergency-contacts/sos-broadcast";
  static const String shares = "/shares";
  static const String analyticsSummary = "/analytics/summary";
  static const String analyticsIntelligence = "/analytics/intelligence";
  static const String settings = "/settings";
}
