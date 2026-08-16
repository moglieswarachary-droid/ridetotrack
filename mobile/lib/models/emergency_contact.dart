class EmergencyContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationshipType;
  final bool isVerified;
  final bool notifyOnCrash;
  final bool notifyOnSos;

  EmergencyContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationshipType,
    required this.isVerified,
    required this.notifyOnCrash,
    required this.notifyOnSos,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      relationshipType: json['relationship_type'] ?? 'friend',
      isVerified: json['is_verified'] ?? true,
      notifyOnCrash: json['notify_on_crash'] ?? true,
      notifyOnSos: json['notify_on_sos'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'relationship_type': relationshipType,
      'notify_on_crash': notifyOnCrash,
      'notify_on_sos': notifyOnSos,
    };
  }
}
