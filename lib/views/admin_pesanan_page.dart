import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';

class AdminPesananPage extends StatefulWidget {
  const AdminPesananPage({super.key});

  @override
  State<AdminPesananPage> createState() => _AdminPesananPageState();
}

class _AdminPesananPageState extends State<AdminPesananPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pesanan = [];
  bool _loading = true;
  String? _apotekId;

  final List<String> _statusTabs = ['Semua', 'Menunggu', 'Diproses', 'Dikirim', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusTabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      _apotekId = user?.pharmacyId;
      _loadPesanan();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPesanan() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.get('/pesanan');
      if (res.statusCode == 200) {
        final all = jsonDecode(res.body) as List<dynamic>;
        final filtered = _apotekId != null
            ? all.where((p) => p['id_apotek']?.toString() == _apotekId).toList()
            : all;
        if (mounted) setState(() { _pesanan = filtered; _loading = false; });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> _filterByStatus(String status) {
    if (status == 'Semua') return _pesanan;
    return _pesanan.where((p) => (p['status'] ?? '').toString().toLowerCase() == status.toLowerCase()).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu': return Colors.orange;
      case 'diproses': return Colors.blueAccent;
      case 'dikirim': return Colors.purple;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }

  List<String> _nextStatuses(String current) {
    switch (current.toLowerCase()) {
      case 'menunggu': return ['Diproses', 'Dibatalkan'];
      case 'diproses': return ['Dikirim'];
      case 'dikirim': return ['Selesai'];
      default: return [];
    }
  }

  Future<void> _ubahStatus(Map<String, dynamic> pesanan, String newStatus) async {
    final id = pesanan['id_pesanan']?.toString() ?? pesanan['id']?.toString();
    if (id == null) return;

    try {
      final authService = AuthService();
      final token = await authService.token;
      final res = await ApiClient.put('/pesanan/$id', {'status': newStatus}, token: token);
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status berhasil diubah ke $newStatus'), backgroundColor: AppColors.darkGreen),
          );
          _loadPesanan();
        }
      } else {
        throw Exception('Gagal mengubah status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 0),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kelola Pesanan', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const Text('Ubah status pengiriman pesanan', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: _statusTabs.map((s) => Tab(text: s)).toList(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : TabBarView(
                    controller: _tabController,
                    children: _statusTabs.map((status) {
                      final list = _filterByStatus(status);
                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black26),
                              const SizedBox(height: 12),
                              Text('Tidak ada pesanan $status', style: const TextStyle(color: Colors.black38)),
                            ],
                          ),
                        );
                      }
                      return RefreshIndicator(
                        onRefresh: _loadPesanan,
                        color: AppColors.darkGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) => _buildPesananCard(list[i]),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(Map<String, dynamic> p) {
    final id = p['id_pesanan']?.toString() ?? p['id']?.toString() ?? '-';
    final status = (p['status'] ?? 'menunggu').toString();
    final nama = p['nama_pemesan'] ?? p['nama'] ?? 'Pelanggan';
    final total = (p['total_harga'] as num? ?? 0).toDouble();
    final tanggal = p['created_at']?.toString().substring(0, 10) ?? '-';
    final nextList = _nextStatuses(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(nama, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined, size: 13, color: Colors.black38),
              const SizedBox(width: 4),
              Text(tanggal, style: const TextStyle(color: Colors.black38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                style: const TextStyle(color: Color(0xFF4299E1), fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (nextList.isNotEmpty)
                Row(
                  children: nextList.map((next) => Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: next == 'Dibatalkan' ? Colors.red : AppColors.darkGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                      ),
                      onPressed: () => _ubahStatus(p, next),
                      child: Text(next, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )).toList(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
