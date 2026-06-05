import 'dart:convert';
import '../models/product_model.dart';
import 'api_client.dart';

class ProductService {
  // Fetch active products
  Future<List<ProductModel>> getActiveProducts() async {
    final response = await ApiClient.get('/obat');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProductModel.fromJson(json)).toList();
    }
    return [];
  }

  // Fetch all products
  Future<List<ProductModel>> getAllProducts() async {
    return await getActiveProducts();
  }

  // Tambah produk (Admin)
  Future<void> addProduct(ProductModel product, {String? token}) async {
    final response = await ApiClient.post(
      '/obat',
      product.toJson(),
      token: token,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Gagal menambah obat',
      );
    }
  }

  // Update produk (Admin)
  Future<void> updateProduct(
    String id,
    ProductModel product, {
    String? token,
  }) async {
    final response = await ApiClient.put(
      '/obat/$id',
      product.toJson(),
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Gagal mengupdate obat',
      );
    }
  }

  // Hapus produk (Admin)
  Future<void> deleteProduct(String id, {String? token}) async {
    final response = await ApiClient.delete('/obat/$id', token: token);
    if (response.statusCode != 200) {
      throw Exception(
        jsonDecode(response.body)['message'] ?? 'Gagal menghapus obat',
      );
    }
  }
}
