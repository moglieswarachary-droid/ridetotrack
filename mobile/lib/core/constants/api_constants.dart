class ApiConstants {
  static const String defaultBaseUrl = "http://10.0.2.2:8000/api/v1"; // Android emulator localhost alias
  static const String localhostBaseUrl = "http://127.0.0.1:8000/api/v1";
  static const String wsBaseUrl = "ws://10.0.2.2:8000/api/v1";

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
