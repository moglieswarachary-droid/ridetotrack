class TrackingPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double speedKmh;
  final double? heading;
  final double? accuracyM;
  final int? batteryPct;
  final String networkStatus;
  final DateTime timestamp;

  TrackingPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.speedKmh,
    this.heading,
    this.accuracyM,
    this.batteryPct,
    this.networkStatus = "online",
    required this.timestamp,
  });

  factory TrackingPoint.fromJson(Map<String, dynamic> json) {
    return TrackingPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speedKmh: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      batteryPct: json['battery_pct'] as int?,
      networkStatus: json['network_status'] ?? "online",
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed_kmh': speedKmh,
      'heading': heading,
      'accuracy_m': accuracyM,
      'battery_pct': batteryPct,
      'network_status': networkStatus,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
