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

  /// Load all orders, optionally filtered by apotek ID.
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

        // Filter di-sisi client juga sebagai fallback, meskipun backend sudah menyaringnya
        pesanan = apotekId != null
            ? all.where((p) => p['id_apotek']?.toString() == apotekId).toList()
            : all;
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

  /// Filter orders by status tab name.
  List<dynamic> filterByStatus(String status) {
    if (status == 'Semua') return pesanan;
    return pesanan.where((p) {
      final stat = (p['status_pesanan'] ?? p['status'] ?? '').toString().toLowerCase();
      // Konversi status 'pending' ke 'menunggu' agar sesuai dengan tab filter
      final normalized = stat == 'pending' ? 'menunggu' : stat;
      return normalized == status.toLowerCase();
    }).toList();
  }

  /// Get color for a given order status.
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

  /// Get list of next possible statuses for a given current status.
  List<String> nextStatuses(String current) {
    switch (current.toLowerCase()) {
      case 'pending':
      case 'menunggu': return ['Diproses', 'Dibatalkan'];
      case 'diproses': return ['Dikirim'];
      case 'dikirim': return ['Selesai'];
      default: return [];
    }
  }

  /// Normalize raw status (convert 'pending' to 'menunggu').
  String normalizeStatus(String rawStatus) {
    return rawStatus.toLowerCase() == 'pending' ? 'menunggu' : rawStatus;
  }

  /// Get customer name from order data.
  String getCustomerName(Map<String, dynamic> p) {
    final userMap = p['users'] as Map<String, dynamic>?;
    return userMap?['nama'] ?? p['nama_pemesan'] ?? p['nama'] ?? 'Pelanggan';
  }

  /// Format date string from order data.
  String formatDate(Map<String, dynamic> p) {
    final dateRaw = p['tanggal_pesanan'] ?? p['created_at'];
    if (dateRaw != null) {
      return dateRaw.toString().substring(0, 10);
    }
    return '-';
  }

  /// Format currency value.
  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  /// Change order status via API.
  Future<void> ubahStatus(Map<String, dynamic> pesananItem, String newStatus, String? apotekId) async {
    final id = pesananItem['id_pesanan']?.toString() ?? pesananItem['id']?.toString();
    if (id == null) return;

    successMessage = null;
    errorMessage = null;

    try {
      final authService = AuthService();
      final token = await authService.token;
      // Gunakan 'status_pesanan' agar sesuai dengan payload controller backend
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
}
