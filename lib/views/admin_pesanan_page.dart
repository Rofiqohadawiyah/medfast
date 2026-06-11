import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/admin_pesanan_controller.dart';
import '../utils/colors.dart';

class AdminPesananPage extends StatelessWidget {
  const AdminPesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminPesananController(),
      child: const _AdminPesananUI(),
    );
  }
}

class _AdminPesananUI extends StatefulWidget {
  const _AdminPesananUI();

  @override
  State<_AdminPesananUI> createState() => _AdminPesananUIState();
}

class _AdminPesananUIState extends State<_AdminPesananUI> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _apotekId;

  @override
  void initState() {
    super.initState();
    final controller = Provider.of<AdminPesananController>(context, listen: false);
    _tabController = TabController(length: controller.statusTabs.length, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      _apotekId = user?.pharmacyId;
      controller.loadPesanan(_apotekId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminPesananController>();

    // Show feedback messages
    if (controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
        );
        controller.errorMessage = null;
      });
    }
    if (controller.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.successMessage!), backgroundColor: AppColors.darkGreen),
        );
        controller.successMessage = null;
      });
    }

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
                  tabs: controller.statusTabs.map((s) => Tab(text: s)).toList(),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : TabBarView(
                    controller: _tabController,
                    children: controller.statusTabs.map((status) {
                      final list = controller.filterByStatus(status);
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
                        onRefresh: () async => controller.loadPesanan(_apotekId),
                        color: AppColors.darkGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) => _buildPesananCard(controller, list[i]),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(AdminPesananController controller, Map<String, dynamic> p) {
    final rawStatus = (p['status_pesanan'] ?? p['status'] ?? 'menunggu').toString();
    final status = controller.normalizeStatus(rawStatus);
    final nama = controller.getCustomerName(p);
    final total = (p['total_harga'] as num? ?? 0).toDouble();
    final tanggal = controller.formatDate(p);
    final nextList = controller.nextStatuses(status);

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
              Expanded(
                child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(color: controller.statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
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
                'Rp ${controller.formatCurrency(total)}',
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
                      onPressed: () => controller.ubahStatus(p, next, _apotekId),
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
