import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'admin_main_screen.dart';
import 'chat_rooms_page.dart';

class AdminBerandaPage extends StatefulWidget {
  const AdminBerandaPage({super.key});

  @override
  State<AdminBerandaPage> createState() => _AdminBerandaPageState();
}

class _AdminBerandaPageState extends State<AdminBerandaPage> {
  int _totalProduk = 0;
  int _pesananPending = 0;
  int _pesananDiproses = 0;
  int _pesananSelesai = 0;
  double _totalPendapatan = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final apotekId = user?.pharmacyId;

      final authService = AuthService();
      final token = await authService.token;

      final obatEndpoint = apotekId != null ? '/stok-obat?id_apotek=$apotekId' : '/obat';
      final results = await Future.wait([
        ApiClient.get(obatEndpoint, token: token),
        ApiClient.get('/pesanan', token: token),
      ]);

      final obatRes = results[0];
      final pesananRes = results[1];

      int totalProduk = 0;
      if (obatRes.statusCode == 200) {
        totalProduk = (jsonDecode(obatRes.body) as List).length;
      }

      int pending = 0, diproses = 0, selesai = 0;
      double pendapatan = 0;
      if (pesananRes.statusCode == 200) {
        final List<dynamic> allPesanan = jsonDecode(pesananRes.body);
        final pesanan = apotekId != null
            ? allPesanan.where((p) => p['id_apotek']?.toString() == apotekId).toList()
            : allPesanan;

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

      if (mounted) {
        setState(() {
          _totalProduk = totalProduk;
          _pesananPending = pending;
          _pesananDiproses = diproses;
          _pesananSelesai = selesai;
          _totalPendapatan = pendapatan;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: RefreshIndicator(
        onRefresh: _loadSummary,
        color: AppColors.darkGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ─── Header ────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 30),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 14),
                              SizedBox(width: 4),
                              Text('Admin Panel', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Halo, ${user?.name ?? 'Admin'}! 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      user?.pharmacyId != null ? 'Apotek ID: ${user!.pharmacyId}' : 'Kelola apotek kamu di sini.',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Quick Stats ────────────────────────────────────
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _statCard('Total Produk', '$_totalProduk', Icons.medication_rounded, AppColors.darkGreen),
                      _statCard('Menunggu', '$_pesananPending', Icons.schedule_rounded, Colors.orange),
                      _statCard('Diproses', '$_pesananDiproses', Icons.local_shipping_rounded, Colors.blueAccent),
                      _statCard('Selesai', '$_pesananSelesai', Icons.check_circle_rounded, Colors.green),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Total Pendapatan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.darkGreen, Color(0xFF2D3748)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white70, size: 32),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pendapatan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              'Rp ${_totalPendapatan.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Menu Cepat ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Menu Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _quickMenu(context, Icons.receipt_long_rounded, AppColors.darkGreen, 'Pesanan', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(1);
                      }),
                      _quickMenu(context, Icons.medication_rounded, Colors.blueAccent, 'Produk', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(2);
                      }),
                      _quickMenu(context, Icons.chat_bubble_rounded, const Color(0xFFEE4D2D), 'Chat', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatRoomsPage()),
                        );
                      }),
                      _quickMenu(context, Icons.person_rounded, Colors.purple, 'Profil', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(3);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(color: Colors.black45, fontSize: 11)),
              Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickMenu(BuildContext context, IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}

