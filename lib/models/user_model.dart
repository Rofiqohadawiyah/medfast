class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'admin' or 'pelanggan'
  final String phone;
  final String? pharmacyId;
  final String? pharmacyName;
  final String? alamat;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    this.pharmacyId,
    this.pharmacyName,
    this.alamat,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'pelanggan',
      phone: data['phone'] ?? '',
      pharmacyId: data['pharmacyId'],
      pharmacyName: data['pharmacyName'],
      alamat: data['alamat'] ?? data['address'],
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['id_user'] ?? json['uid'] ?? '').toString(),
      name: json['nama'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'pelanggan',
      phone: json['no_hp'] ?? json['phone'] ?? '',
      pharmacyId: (json['id_apotek'] ?? json['pharmacyId'])?.toString(),
      pharmacyName: json['nama_apotek'] ?? json['pharmacyName'],
      alamat: json['alamat'] ?? json['address'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'pharmacyId': pharmacyId,
      'pharmacyName': pharmacyName,
      'address': alamat,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': name,
      'email': email,
      'role': role,
      'no_hp': phone,
      'id_apotek': pharmacyId != null ? int.tryParse(pharmacyId!) : null,
      'alamat': alamat,
    };
  }
}

