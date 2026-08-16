class GeofenceModel {
  final String id;
  final String bikeId;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final bool isActive;
  final bool notifyOnExit;

  GeofenceModel({
    required this.id,
    required this.bikeId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.isActive,
    required this.notifyOnExit,
  });

  factory GeofenceModel.fromJson(Map<String, dynamic> json) {
    return GeofenceModel(
      id: json['id'] ?? '',
      bikeId: json['bike_id'] ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? 100.0,
      isActive: json['is_active'] ?? true,
      notifyOnExit: json['notify_on_exit'] ?? true,
    );
  }
}
