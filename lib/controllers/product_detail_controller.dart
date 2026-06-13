import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';

class ProductDetailController extends ChangeNotifier {
  bool isLoadingApotek = true;
  int? idApotek;
  String namaApotek = 'Apotek Mitra';
  String alamatApotek = 'Detail alamat apotek...';
  String jamOperasional = '08.00 - 21.00';
  double? apotekLat;
  double? apotekLng;
  String? noHpApotek;

  double distanceInKm = 2.5; // Fallback distance (2.5 km -> Rp 10.000)
  bool isCalculatingDistance = false;

  Future<void> fetchApotekInfo(dynamic targetId, String userAddress) async {
    isLoadingApotek = true;
    notifyListeners();

    List<dynamic> allApoteks = [];
    try {
      final response = await ApiClient.get('/apotek');
      if (response.statusCode == 200) {
        allApoteks = jsonDecode(response.body);
      }
    } catch (_) {}

    try {
      final response = await ApiClient.get('/stok-obat');
      if (response.statusCode == 200) {
        final List<dynamic> stockList = jsonDecode(response.body);
        final match = stockList.firstWhere(
          (item) => item['id_obat']?.toString() == targetId?.toString(),
          orElse: () => null,
        );
        if (match != null && match['id_apotek'] != null) {
          final detailedApotek = allApoteks.firstWhere(
            (a) => a['id_apotek']?.toString() == match['id_apotek']?.toString(),
            orElse: () => null,
          );
          if (detailedApotek != null) {
            idApotek = detailedApotek['id_apotek'];
            namaApotek = detailedApotek['nama_apotek'] ?? 'Apotek Mitra';
            alamatApotek =
                detailedApotek['alamat'] ?? 'Detail alamat apotek...';
            jamOperasional =
                detailedApotek['jam_operasional'] ?? '08.00 - 21.00';
            apotekLat = (detailedApotek['latitude'] as num?)?.toDouble();
            apotekLng = (detailedApotek['longitude'] as num?)?.toDouble();
            noHpApotek = detailedApotek['no_hp']?.toString();
            isLoadingApotek = false;
            notifyListeners();
            _calculateDistance(userAddress);
            return;
          }
        }
      }
    } catch (_) {}

    if (allApoteks.isNotEmpty) {
      final apotek = allApoteks[0];
      idApotek = apotek['id_apotek'];
      namaApotek = apotek['nama_apotek'] ?? 'Apotek Mitra';
      alamatApotek = apotek['alamat'] ?? 'Detail alamat apotek...';
      jamOperasional = apotek['jam_operasional'] ?? '08.00 - 21.00';
      apotekLat = (apotek['latitude'] as num?)?.toDouble();
      apotekLng = (apotek['longitude'] as num?)?.toDouble();
      noHpApotek = apotek['no_hp']?.toString();
      isLoadingApotek = false;
      notifyListeners();
      _calculateDistance(userAddress);
      return;
    }

    idApotek = 1;
    isLoadingApotek = false;
    notifyListeners();
  }

  Future<void> _calculateDistance(String address) async {
    if (apotekLat == null || apotekLng == null) return;
    isCalculatingDistance = true;
    notifyListeners();

    double? userLat;
    double? userLng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          userLat = pos.latitude;
          userLng = pos.longitude;
        }
      }
    } catch (_) {}

    if ((userLat == null || userLng == null) && address.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1',
        );
        final searchRes = await http.get(
          searchUrl,
          headers: {'User-Agent': 'MedFastApp/1.0'},
        );
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            userLat = double.parse(list[0]['lat']);
            userLng = double.parse(list[0]['lon']);
          }
        }
      } catch (_) {}
    }

    if (userLat != null &&
        userLng != null &&
        apotekLat != null &&
        apotekLng != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        apotekLat!,
        apotekLng!,
        userLat,
        userLng,
      );
      distanceInKm = distanceInMeters / 1000.0;
    }

    isCalculatingDistance = false;
    notifyListeners();
  }

  bool isApotekOpen() {
    if (jamOperasional == null) return false;
    final String jamStr = jamOperasional.toString();
    if (jamStr.isEmpty || jamStr == '-') return false;
    try {
      final parts = jamStr.split('-');
      if (parts.length != 2) return false;

      final startStr = parts[0].trim().replaceAll('.', ':');
      final endStr = parts[1].trim().replaceAll('.', ':');

      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      if (startParts.length < 2 || endParts.length < 2) return false;

      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);

      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);

      final now = DateTime.now();
      final nowHour = now.hour;
      final nowMin = now.minute;

      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;
      final nowMinutes = nowHour * 60 + nowMin;

      if (startMinutes <= endMinutes) {
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      } else {
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  // --- Checkout Sheet State ---
  bool isSubmitting = false;
  String paymentMethod = 'COD';
  bool useCoins = false;
  int quantity = 1;

  void setPaymentMethod(String method) {
    paymentMethod = method;
    notifyListeners();
  }

  void setUseCoins(bool value) {
    useCoins = value;
    notifyListeners();
  }

  void incrementQuantity() {
    quantity++;
    notifyListeners();
  }

  void decrementQuantity() {
    if (quantity > 1) {
      quantity--;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitDirectCheckout({
    required Map<String, dynamic> product,
    required String address,
    required int shippingFee,
  }) async {
    isSubmitting = true;
    notifyListeners();

    final price = product['harga'] ?? product['price'] ?? 0;
    final coinDiscount = useCoins ? 1000 : 0;
    final totalHarga = (price * quantity) + shippingFee - coinDiscount;
    final idObat = product['id_obat'] ?? product['id'];

    try {
      final authService = AuthService();
      final token = await authService.token;

      final pesananRes = await ApiClient.post('/pesanan', {
        'id_apotek': idApotek ?? 1,
        'total_harga': totalHarga,
        'status_pesanan': 'menunggu',
        'detail_items': [
          {'id_obat': idObat, 'jumlah': quantity, 'harga_satuan': price},
        ],
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
          'alamat_tujuan': address,
          'status_pengiriman': 'pending',
        }, token: token);

        if (paymentMethod == 'Midtrans') {
          final paymentService = PaymentService();
          final snapData = await paymentService.getSnapToken(idPesanan);
          isSubmitting = false;
          notifyListeners();
          return {
            'success': true,
            'method': 'Midtrans',
            'payment_url': snapData != null ? snapData['payment_url'] : null,
            'idPesanan': idPesanan,
          };
        } else {
          isSubmitting = false;
          notifyListeners();
          return {'success': true, 'method': 'COD'};
        }
      } else {
        final errorMsg =
            jsonDecode(pesananRes.body)['message'] ?? 'Gagal membuat pesanan';
        throw Exception(errorMsg);
      }
    } catch (e) {
      isSubmitting = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }
}
