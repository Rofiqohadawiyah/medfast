import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AdminPesananController extends ChangeNotifier {
  List<dynamic> pesanan = [];
  bool isLoading = true;
  String? errorMessage;
  String? successMessage;

  final List<String> statusTabs = ['Semua', 'Menunggu', 'Diproses', 'Dikirim', 'Selesai', 'Dibatalkan'];


  Future<void> loadPesanan(String? apotekId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;
      final res = await ApiClient.get('/pesanan', token: token);
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body) as List<dynamic>;


        final filtered = apotekId != null
            ? all.where((p) => p['id_apotek']?.toString() == apotekId).toList()
            : all;


        final futures = filtered.map((o) async {
          final idPesanan = o['id_pesanan'];
          if (idPesanan != null) {
            try {
              final detailResponse = await ApiClient.get('/pesanan/$idPesanan', token: token);
              if (detailResponse.statusCode == 200) {
                return jsonDecode(detailResponse.body);
              }
            } catch (e) {
              debugPrint('Error fetching detail for order $idPesanan: $e');
            }
          }
          return o;
        }).toList();

        pesanan = await Future.wait(futures);
      } else {
        errorMessage = 'Gagal memuat pesanan';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  List<dynamic> filterByStatus(String status) {
    if (status == 'Semua') return pesanan;
    return pesanan.where((p) {
      final stat = (p['status_pesanan'] ?? p['status'] ?? '').toString().toLowerCase();

      final normalized = stat == 'pending' ? 'menunggu' : stat;
      return normalized == status.toLowerCase();
    }).toList();
  }


  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu': return Colors.orange;
      case 'diproses': return Colors.blueAccent;
      case 'dikirim': return Colors.purple;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }


  List<String> nextStatuses(String current) {
    switch (current.toLowerCase()) {
      case 'pending':
      case 'menunggu': return ['Diproses', 'Dibatalkan'];
      case 'diproses': return ['Dikirim'];
      case 'dikirim': return ['Selesai'];
      default: return [];
    }
  }


  String normalizeStatus(String rawStatus) {
    return rawStatus.toLowerCase() == 'pending' ? 'menunggu' : rawStatus;
  }


  String getCustomerName(Map<String, dynamic> p) {
    final userMap = p['users'] as Map<String, dynamic>?;
    return userMap?['nama'] ?? p['nama_pemesan'] ?? p['nama'] ?? 'Pelanggan';
  }


  String formatDate(Map<String, dynamic> p) {
    final dateRaw = p['tanggal_pesanan'] ?? p['created_at'];
    if (dateRaw != null) {
      return dateRaw.toString().substring(0, 10);
    }
    return '-';
  }


  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }


  Future<void> ubahStatus(Map<String, dynamic> pesananItem, String newStatus, String? apotekId) async {
    final id = pesananItem['id_pesanan']?.toString() ?? pesananItem['id']?.toString();
    if (id == null) return;

    successMessage = null;
    errorMessage = null;

    try {
      final authService = AuthService();
      final token = await authService.token;

      final res = await ApiClient.put('/pesanan/$id', {'status_pesanan': newStatus.toLowerCase()}, token: token);
      if (res.statusCode == 200) {
        successMessage = 'Status berhasil diubah ke $newStatus';
        notifyListeners();
        await loadPesanan(apotekId);
      } else {
        final errMsg = jsonDecode(res.body)['message'] ?? 'Gagal mengubah status';
        errorMessage = errMsg;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error: $e';
      notifyListeners();
    }
  }


  Future<void> konfirmasiPembayaran(String paymentId, String? apotekId) async {
    successMessage = null;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;
      final res = await ApiClient.put('/pembayaran/$paymentId', {'status_pembayaran': 'lunas'}, token: token);
      if (res.statusCode == 200) {
        successMessage = 'Pembayaran berhasil dikonfirmasi sebagai Lunas';
        notifyListeners();
        await loadPesanan(apotekId);
      } else {
        final errMsg = jsonDecode(res.body)['message'] ?? 'Gagal mengonfirmasi pembayaran';
        errorMessage = errMsg;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error: $e';
      notifyListeners();
    }
  }


  Future<int?> createChatRoom(int userId, int idAdmin, int idApotek) async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post('/chat/room', {
        'id_pelanggan': userId,
        'id_admin': idAdmin,
        'id_apotek': idApotek,
      }, token: token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        return room['id_chat'];
      } else {
        errorMessage = 'Gagal membuat room chat';
        notifyListeners();
        return null;
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
