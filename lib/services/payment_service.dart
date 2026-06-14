import 'dart:convert';
import 'api_client.dart';
import 'auth_service.dart';

class PaymentService {
  final AuthService _authService = AuthService();



  Future<Map<String, dynamic>?> getSnapToken(int idPesanan) async {
    try {
      final token = await _authService.token;
      final response = await ApiClient.post(
        '/pembayaran/snap-token',
        {'id_pesanan': idPesanan},
        token: token,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'snap_token': data['snap_token'],
          'payment_url': data['payment_url'] ?? data['redirect_url'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Gagal mendapatkan token Midtrans dari server');
      }
    } catch (e) {
      print('Error getSnapToken: $e');
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
