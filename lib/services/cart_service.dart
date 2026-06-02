import 'dart:convert';
import 'api_client.dart';
import 'auth_service.dart';

class CartService {
  final AuthService _authService = AuthService();

  // 1. Ambil daftar keranjang belanja
  Future<List<dynamic>> getCart() async {
    try {
      final token = await _authService.token;
      final response = await ApiClient.get('/keranjang', token: token);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print("Error getting cart: $e");
      return [];
    }
  }

  // 2. Tambah item ke keranjang
  Future<void> addToCart(int idObat, int quantity) async {
    final token = await _authService.token;
    final response = await ApiClient.post(
      '/keranjang',
      {
        'id_obat': idObat,
        'jumlah': quantity,
      },
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal menambah ke keranjang');
    }
  }

  // 3. Update jumlah kuantitas item
  Future<void> updateQuantity(int idKeranjang, int quantity) async {
    final token = await _authService.token;
    final response = await ApiClient.put(
      '/keranjang/$idKeranjang',
      {
        'jumlah': quantity,
      },
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal memperbarui kuantitas');
    }
  }

  // 4. Hapus item dari keranjang
  Future<void> deleteItem(int idKeranjang) async {
    final token = await _authService.token;
    final response = await ApiClient.delete(
      '/keranjang/$idKeranjang',
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal menghapus item keranjang');
    }
  }

  // 5. Kosongkan seluruh keranjang
  Future<void> clearCart() async {
    final token = await _authService.token;
    final response = await ApiClient.delete(
      '/keranjang',
      token: token,
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal mengosongkan keranjang');
    }
  }
}
