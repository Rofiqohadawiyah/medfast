
class ProductModel {
  final String? id;
  final String name;
  final String category;
  final String description;
  final int price;
  final int stock;
  final String imageUrl;
  final String pharmacyName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
    required this.pharmacyName,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      id: documentId,
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      price: data['price'] ?? 0,
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      pharmacyName: data['pharmacyName'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null ? DateTime.tryParse(data['createdAt'].toString()) : null,
      updatedAt: data['updatedAt'] != null ? DateTime.tryParse(data['updatedAt'].toString()) : null,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: (json['id_obat'] ?? json['id'] ?? '').toString(),
      name: json['nama_obat'] ?? json['name'] ?? '',
      category: json['kategori'] ?? json['category'] ?? '',
      description: json['deskripsi'] ?? json['description'] ?? '',
      price: (json['harga'] ?? json['price'] ?? 0) is int
          ? (json['harga'] ?? json['price'] ?? 0)
          : (json['harga'] ?? json['price'] ?? 0.0).toInt(),
      stock: json['jumlah_stok'] ?? json['stock'] ?? 0,
      imageUrl: json['gambar'] ?? json['imageUrl'] ?? '',
      pharmacyName: json['nama_apotek'] ?? json['pharmacyName'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'pharmacyName': pharmacyName,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_obat': name,
      'deskripsi': description,
      'kategori': category,
      'harga': price,
      'gambar': imageUrl,
    };
  }
}
