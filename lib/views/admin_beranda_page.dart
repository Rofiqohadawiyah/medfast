import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/admin_beranda_controller.dart';
import '../utils/colors.dart';
import 'admin_main_screen.dart';
import 'chat_rooms_page.dart';

class AdminBerandaPage extends StatelessWidget {
  const AdminBerandaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminBerandaController(),
      child: const _AdminBerandaUI(),
    );
  }
}

class _AdminBerandaUI extends StatefulWidget {
  const _AdminBerandaUI();

  @override
  State<_AdminBerandaUI> createState() => _AdminBerandaUIState();
}

class _AdminBerandaUIState extends State<_AdminBerandaUI> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      context.read<AdminBerandaController>().loadSummary(user?.pharmacyId);
    });
  }

  void _refresh() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    context.read<AdminBerandaController>().loadSummary(user?.pharmacyId);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final controller = context.watch<AdminBerandaController>();

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: AppColors.darkGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [

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


              if (controller.isLoading)
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
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _statCard('Total Produk', '${controller.totalProduk}', Icons.medical_information_outlined, const Color(0xFF4299E1)),
                      _statCard('Menunggu', '${controller.pesananPending}', Icons.schedule_rounded, Colors.orange),
                      _statCard('Diproses', '${controller.pesananDiproses}', Icons.local_shipping_outlined, const Color(0xFF64748B)),
                      _statCard('Selesai', '${controller.pesananSelesai}', Icons.check_circle_outline, Colors.green),
                    ],
                  ),
                ),

                const SizedBox(height: 24),


                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Pendapatan', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                'Rp ${controller.formatCurrency(controller.totalPendapatan)}',
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),


                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Menu Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _quickMenu(context, Icons.receipt_long_outlined, 'Pesanan', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(1);
                      }),
                      _quickMenu(context, Icons.medical_services_outlined, 'Produk', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(2);
                      }),
                      _quickMenu(context, Icons.chat_bubble_outline, 'Chat', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatRoomsPage()),
                        );
                      }),
                      _quickMenu(context, Icons.person_outline, 'Profil', () {
                        final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                        shell?.setSelectedIndex(3);
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),


                if (controller.latestPesanan.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Pesanan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                              GestureDetector(
                                onTap: () {
                                  final shell = context.findAncestorStateOfType<AdminMainScreenState>();
                                  shell?.setSelectedIndex(1);
                                },
                                child: const Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ...controller.latestPesanan.map((p) => _buildRecentOrderItem(controller, p)).toList(),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 60),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.replaceFirst(' ', '\n'),
                  style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _quickMenu(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58, height: 58,
            decoration: const BoxDecoration(color: Color(0xFFEAF0FC), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildRecentOrderItem(AdminBerandaController controller, Map<String, dynamic> data) {
    final idPesanan = data['id_pesanan'] ?? data['id'] ?? '-';
    final customerName = data['nama_pembeli'] ?? data['customer_name'] ?? 'Pelanggan';
    final status = controller.getDisplayStatus(data);
    final bgStatus = controller.getStatusBgColor(status);
    final textStatus = controller.getStatusTextColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Color(0xFFEAF0FC), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_outlined, color: AppColors.darkGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#MF-$idPesanan', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 4),
                Text(customerName, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: bgStatus, borderRadius: BorderRadius.circular(20)),
            child: Text(
              status,
              style: TextStyle(color: textStatus, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
