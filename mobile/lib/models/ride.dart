class Ride {
  final String id;
  final String sessionId;
  final String bikeId;
  final double totalDistanceKm;
  final int durationSeconds;
  final int movingDurationSeconds;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double elevationGainM;
  final double elevationLossM;
  final String? startAddress;
  final String? endAddress;
  final String? encodedPolyline;
  final DateTime startedAt;
  final DateTime endedAt;

  Ride({
    required this.id,
    required this.sessionId,
    required this.bikeId,
    required this.totalDistanceKm,
    required this.durationSeconds,
    required this.movingDurationSeconds,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.elevationGainM,
    required this.elevationLossM,
    this.startAddress,
    this.endAddress,
    this.encodedPolyline,
    required this.startedAt,
    required this.endedAt,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'] ?? '',
      sessionId: json['session_id'] ?? '',
      bikeId: json['bike_id'] ?? '',
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] ?? 0,
      movingDurationSeconds: json['moving_duration_seconds'] ?? 0,
      averageSpeedKmh: (json['average_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      maxSpeedKmh: (json['max_speed_kmh'] as num?)?.toDouble() ?? 0.0,
      elevationGainM: (json['elevation_gain_m'] as num?)?.toDouble() ?? 0.0,
      elevationLossM: (json['elevation_loss_m'] as num?)?.toDouble() ?? 0.0,
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      encodedPolyline: json['encoded_polyline'],
      startedAt: DateTime.parse(json['started_at']),
      endedAt: DateTime.parse(json['ended_at']),
    );
  }
}
