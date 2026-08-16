class AlertModel {
  final String id;
  final String bikeId;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final double? latitude;
  final double? longitude;
  final bool isRead;
  final bool isAcknowledged;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.bikeId,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    this.latitude,
    this.longitude,
    required this.isRead,
    required this.isAcknowledged,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] ?? '',
      bikeId: json['bike_id'] ?? '',
      alertType: json['alert_type'] ?? 'info',
      severity: json['severity'] ?? 'warning',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isRead: json['is_read'] ?? false,
      isAcknowledged: json['is_acknowledged'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
