class Bike {
  final String id;
  final String userId;
  final String name;
  final String manufacturer;
  final String model;
  final String? variant;
  final String registrationNumber;
  final int year;
  final double odometerKm;
  final String? photoUrl;
  final bool isActive;
  final String preferredTrackingMode;

  Bike({
    required this.id,
    required this.userId,
    required this.name,
    required this.manufacturer,
    required this.model,
    this.variant,
    required this.registrationNumber,
    required this.year,
    required this.odometerKm,
    this.photoUrl,
    required this.isActive,
    required this.preferredTrackingMode,
  });

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      manufacturer: json['manufacturer'] ?? '',
      model: json['model'] ?? '',
      variant: json['variant'],
      registrationNumber: json['registration_number'] ?? '',
      year: json['year'] ?? 2024,
      odometerKm: (json['odometer_km'] as num?)?.toDouble() ?? 0.0,
      photoUrl: json['photo_url'],
      isActive: json['is_active'] ?? false,
      preferredTrackingMode: json['preferred_tracking_mode'] ?? 'balanced',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'manufacturer': manufacturer,
      'model': model,
      'variant': variant,
      'registration_number': registrationNumber,
      'year': year,
      'odometer_km': odometerKm,
      'photo_url': photoUrl,
      'is_active': isActive,
      'preferred_tracking_mode': preferredTrackingMode,
    };
  }
}
