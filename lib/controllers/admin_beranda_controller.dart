import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AdminBerandaController extends ChangeNotifier {
  int totalProduk = 0;
  int pesananPending = 0;
  int pesananDiproses = 0;
  int pesananSelesai = 0;
  double totalPendapatan = 0;
  bool isLoading = true;
  List<dynamic> latestPesanan = [];
  String? errorMessage;


  Future<void> loadSummary(String? apotekId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final obatEndpoint = apotekId != null ? '/stok-obat?id_apotek=$apotekId' : '/obat';
      final results = await Future.wait([
        ApiClient.get(obatEndpoint, token: token),
        ApiClient.get('/pesanan', token: token),
      ]);

      final obatRes = results[0];
      final pesananRes = results[1];

      int produkCount = 0;
      if (obatRes.statusCode == 200) {
        produkCount = (jsonDecode(obatRes.body) as List).length;
      }

      int pending = 0, diproses = 0, selesai = 0;
      double pendapatan = 0;
      List<dynamic> latest = [];

      if (pesananRes.statusCode == 200) {
        final List<dynamic> allPesanan = jsonDecode(pesananRes.body);
        final pesanan = apotekId != null
            ? allPesanan.where((p) => p['id_apotek']?.toString() == apotekId).toList()
            : allPesanan;


        pesanan.sort((a, b) {
          final idA = a['id_pesanan'] ?? a['id'] ?? 0;
          final idB = b['id_pesanan'] ?? b['id'] ?? 0;
          if (idA is int && idB is int) return idB.compareTo(idA);
          return 0;
        });

        latest = pesanan.take(3).toList();

        for (var p in pesanan) {
          final rawStatus = (p['status_pesanan'] ?? p['status'] ?? '').toString().toLowerCase();
          final status = rawStatus == 'pending' ? 'menunggu' : rawStatus;

          if (status == 'menunggu') pending++;
          if (status == 'diproses') diproses++;
          if (status == 'selesai') {
            selesai++;
            pendapatan += (p['total_harga'] as num? ?? 0).toDouble();
          }
        }
      }

      totalProduk = produkCount;
      pesananPending = pending;
      pesananDiproses = diproses;
      pesananSelesai = selesai;
      totalPendapatan = pendapatan;
      latestPesanan = latest;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  String formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }


  String getDisplayStatus(Map<String, dynamic> data) {
    final rawStatus = (data['status_pesanan'] ?? data['status'] ?? '').toString().toUpperCase();
    return rawStatus == 'PENDING' ? 'MENUNGGU' : rawStatus;
  }


  Color getStatusBgColor(String status) {
    if (status == 'MENUNGGU') return const Color(0xFFFFF3E0);
    if (status == 'DIPROSES') return const Color(0xFFE3F2FD);
    if (status == 'SELESAI') return const Color(0xFFE8F5E9);
    return const Color(0xFFF5F5F5);
  }


  Color getStatusTextColor(String status) {
    if (status == 'MENUNGGU') return const Color(0xFFFF9800);
    if (status == 'DIPROSES') return const Color(0xFF2196F3);
    if (status == 'SELESAI') return const Color(0xFF4CAF50);
    return const Color(0xFF9E9E9E);
  }
}
