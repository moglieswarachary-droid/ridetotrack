class ParkingSpot {
  final String id;
  final String bikeId;
  final double latitude;
  final double longitude;
  final double? accuracyM;
  final String? address;
  final String? note;
  final String? photoUrl;
  final DateTime parkedAt;

  ParkingSpot({
    required this.id,
    required this.bikeId,
    required this.latitude,
    required this.longitude,
    this.accuracyM,
    this.address,
    this.note,
    this.photoUrl,
    required this.parkedAt,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] ?? '',
      bikeId: json['bike_id'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracyM: (json['accuracy_m'] as num?)?.toDouble(),
      address: json['address'],
      note: json['note'],
      photoUrl: json['photo_url'],
      parkedAt: DateTime.parse(json['parked_at']),
    );
  }
}
