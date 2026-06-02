class PharmacyModel {
  final String? id;
  final String name;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String openTime;
  final String closeTime;
  final bool isActive;

  PharmacyModel({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.openTime,
    required this.closeTime,
    required this.isActive,
  });

  factory PharmacyModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PharmacyModel(
      id: documentId,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      openTime: data['openTime'] ?? '',
      closeTime: data['closeTime'] ?? '',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'openTime': openTime,
      'closeTime': closeTime,
      'isActive': isActive,
    };
  }
}
