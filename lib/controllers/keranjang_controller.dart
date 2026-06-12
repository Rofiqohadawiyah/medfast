import 'dart:convert';
import 'package:flutter/material.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

class KeranjangController extends ChangeNotifier {
  bool isCheckingOut = false;
  String paymentMethod = 'COD';
  String? errorMessage;

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> prosesCheckout({
    required CartProvider cartProvider,
    required String userAddress,
    List<int>? selectedCartIds,
  }) async {
    if (cartProvider.cartItems.isEmpty) return null;

    isCheckingOut = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      int idApotek = 1;
      try {
        final firstItem = cartProvider.cartItems[0];
        final idObat = firstItem['id_obat'];

        final stockRes = await ApiClient.get('/stok-obat');
        if (stockRes.statusCode == 200) {
          final List<dynamic> stocks = jsonDecode(stockRes.body);
          final match = stocks.firstWhere(
            (s) => s['id_obat']?.toString() == idObat?.toString(),
            orElse: () => null,
          );
          if (match != null && match['id_apotek'] != null) {
            idApotek = (match['id_apotek'] as num).toInt();
          }
        }
      } catch (_) {}

      final itemsToCheckout = selectedCartIds != null
          ? cartProvider.cartItems.where((item) {
              final idKeranjang = (item['id_keranjang'] as num).toInt();
              return selectedCartIds.contains(idKeranjang);
            }).toList()
          : cartProvider.cartItems;

      if (itemsToCheckout.isEmpty) {
        throw Exception('Tidak ada barang terpilih untuk checkout');
      }

      final detailItems = itemsToCheckout.map((item) {
        final obat = item['obat'] as Map<String, dynamic>? ?? {};
        final price = (obat['harga'] ?? obat['price'] ?? 0) as num;
        return {
          'id_obat': item['id_obat'],
          'jumlah': item['jumlah'],
          'harga_satuan': price.toDouble(),
        };
      }).toList();

      double calculatedTotal = 0;
      for (var item in itemsToCheckout) {
        final qty = (item['jumlah'] as num? ?? 0).toDouble();
        final obat = item['obat'] as Map<String, dynamic>?;
        if (obat != null) {
          final price = (obat['harga'] ?? obat['price'] ?? 0) as num;
          calculatedTotal += qty * price.toDouble();
        }
      }

      final totalHarga = calculatedTotal + 10000; // Flat ongkir

      final pesananRes = await ApiClient.post('/pesanan', {
        'id_apotek': idApotek,
        'total_harga': totalHarga,
        'status_pesanan': 'menunggu',
        'detail_items': detailItems,
      }, token: token);

      if (pesananRes.statusCode == 201) {
        final pesananData = jsonDecode(pesananRes.body);
        final idPesanan = pesananData['pesanan']['id_pesanan'];

        await ApiClient.post('/pembayaran', {
          'id_pesanan': idPesanan,
          'metode_pembayaran': paymentMethod,
          'status_pembayaran': 'belum_bayar',
        }, token: token);

        await ApiClient.post('/pengiriman', {
          'id_pesanan': idPesanan,
          'alamat_tujuan': userAddress,
          'status_pengiriman': 'pending',
        }, token: token);

        if (selectedCartIds == null || selectedCartIds.length == cartProvider.cartItems.length) {
          await cartProvider.clearCart();
        } else {
          for (var id in selectedCartIds) {
            await cartProvider.deleteItem(id);
          }
        }

        if (paymentMethod == 'Midtrans') {
          final paymentService = PaymentService();
          final snapData = await paymentService.getSnapToken(idPesanan);

          isCheckingOut = false;
          notifyListeners();

          return {
            'success': true,
            'method': 'Midtrans',
            'idPesanan': idPesanan,
            'payment_url': snapData != null ? snapData['payment_url'] : null,
          };
        } else {
          isCheckingOut = false;
          notifyListeners();
          return {'success': true, 'method': 'COD'};
        }
      } else {
        final errorMsg =
            jsonDecode(pesananRes.body)['message'] ?? 'Gagal memproses pesanan';
        throw Exception(errorMsg);
      }
    } catch (e) {
      errorMessage = e.toString();
      isCheckingOut = false;
      notifyListeners();
      return {'success': false, 'error': errorMessage};
    }
  }
}
