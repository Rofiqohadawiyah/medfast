import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/admin_pesanan_controller.dart';
import '../utils/colors.dart';
import 'chat_page.dart';

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

  void _showOrderDetail(BuildContext context, Map<String, dynamic> detail, AdminPesananController controller) {
    final detailItems = detail['detail_pesanan'] ?? [];
    final Map<String, dynamic> pembayaran = (detail['pembayaran'] is List && (detail['pembayaran'] as List).isNotEmpty)
        ? (detail['pembayaran'][0] as Map<String, dynamic>? ?? {})
        : (detail['pembayaran'] is Map ? (detail['pembayaran'] as Map<String, dynamic>) : {});
    final Map<String, dynamic> pengiriman = (detail['pengiriman'] is List && (detail['pengiriman'] as List).isNotEmpty)
        ? (detail['pengiriman'][0] as Map<String, dynamic>? ?? {})
        : (detail['pengiriman'] is Map ? (detail['pengiriman'] as Map<String, dynamic>) : {});
    final Map<String, dynamic> userMap = detail['users'] is Map
        ? (detail['users'] as Map<String, dynamic>)
        : {};
    final status = (detail['status_pesanan'] ?? detail['status'] ?? 'menunggu').toString();
    final normalizedStatus = controller.normalizeStatus(status);
    final nama = controller.getCustomerName(detail);
    final total = (detail['total_harga'] as num? ?? 0).toDouble();
    final tanggal = controller.formatDate(detail);
    final nextList = controller.nextStatuses(normalizedStatus);
    final idPesanan = detail['id_pesanan'] ?? detail['id'] ?? '-';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Detail Pesanan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    _buildStatusBadge(status),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userMap['no_hp'] != null ? 'Pelanggan: $nama (${userMap['no_hp']})' : 'Pelanggan: $nama',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text('ID Pesanan: #MF-$idPesanan', style: const TextStyle(color: Colors.black54)),
                          Text('Tanggal: $tanggal', style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Item list
                const Text('Daftar Obat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...detailItems.map((item) {
                  final obat = item['obat'] ?? {};
                  final name = (obat['nama_obat'] ?? obat['name'] ?? 'Obat').toString();
                  final qty = item['jumlah'] ?? 1;
                  final price = (item['harga_satuan'] ?? 0) as num;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$name (x$qty)', style: const TextStyle(fontSize: 15)),
                        Text('Rp ${controller.formatCurrency((price * qty).toDouble())}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
                const Divider(height: 32),

                // Payment Info
                const Text('Informasi Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metode Pembayaran', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pembayaran['metode_pembayaran'] == 'Midtrans'
                            ? 'Transfer Bank / E-Wallet (Midtrans)'
                            : (pembayaran['metode_pembayaran'] ?? '-'),
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Pembayaran', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(
                      (pembayaran['status_pembayaran'] == 'lunas' || pembayaran['status_pembayaran'] == 'berhasil') ? 'Lunas' : 'Belum Bayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: (pembayaran['status_pembayaran'] == 'lunas' || pembayaran['status_pembayaran'] == 'berhasil') ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Delivery Info
                const Text('Informasi Pengiriman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Pengiriman', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(
                      _formatDeliveryStatus(pengiriman['status_pengiriman']),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Alamat Tujuan:', style: TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    (pengiriman['alamat_tujuan'] != null && pengiriman['alamat_tujuan'].toString().trim().isNotEmpty && pengiriman['alamat_tujuan'].toString() != '-')
                        ? pengiriman['alamat_tujuan'].toString()
                        : (userMap['alamat'] ?? '-').toString(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Divider(height: 32),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rp ${controller.formatCurrency(total)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                  ],
                ),

                // Action Buttons inside sheet
                const SizedBox(height: 24),
                const Text('Aksi Admin', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Konfirmasi Pembayaran Manual
                if (pembayaran['status_pembayaran'] != 'lunas' && pembayaran['status_pembayaran'] != 'berhasil') ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Konfirmasi Pembayaran Manual', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        final pId = pembayaran['id_pembayaran'] ?? pembayaran['id'];
                        if (pId != null) {
                          controller.konfirmasiPembayaran(pId.toString(), _apotekId);
                        } else {
                          // Jika payment ID belum ada (misal COD atau error backend), beritahu admin
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('ID Pembayaran tidak ditemukan untuk pesanan ini')),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                // Chat Pelanggan
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      _hubungiPelanggan(context, detail, controller);
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
                    label: const Text('Chat Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                  ),
                ),
                
                // Ubah Status Pesanan
                if (nextList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Ubah Status Pesanan', style: TextStyle(fontSize: 14, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Row(
                    children: nextList.map((next) {
                      final isCancel = next == 'Dibatalkan';
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCancel ? const Color(0xFFfee2e2) : AppColors.darkGreen,
                              foregroundColor: isCancel ? const Color(0xFFef4444) : Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isCancel ? const BorderSide(color: Color(0xFFfca5a5), width: 1) : BorderSide.none,
                              ),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              controller.ubahStatus(detail, next, _apotekId);
                            },
                            child: Text(
                              next,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isCancel ? const Color(0xFFb91c1c) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
                          itemBuilder: (ctx, i) => _buildPesananCard(context, controller, list[i]),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(BuildContext context, AdminPesananController controller, Map<String, dynamic> p) {
    final rawStatus = (p['status_pesanan'] ?? p['status'] ?? 'menunggu').toString();
    final status = controller.normalizeStatus(rawStatus);
    final nama = controller.getCustomerName(p);
    final total = (p['total_harga'] as num? ?? 0).toDouble();
    final tanggal = controller.formatDate(p);
    final nextList = controller.nextStatuses(status);
    final idPesanan = p['id_pesanan'] ?? p['id'] ?? '-';
    final detailItems = p['detail_pesanan'] as List? ?? [];

    return GestureDetector(
      onTap: () => _showOrderDetail(context, p, controller),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Order ID & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 16, color: Colors.black45),
                  const SizedBox(width: 6),
                  Text(
                    '#MF-$idPesanan',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: controller.statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: controller.statusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.black12, height: 1),
          ),

          // Row 2: Customer Name & Date
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.darkGreen),
              const SizedBox(width: 8),
              Text(
                nama,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
                  const SizedBox(width: 4),
                  Text(
                    tanggal,
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Row 3: Items List
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DAFTAR OBAT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black45,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (detailItems.isNotEmpty)
                  ...detailItems.map((item) {
                    final obat = item['obat'] ?? {};
                    final name = (obat['nama_obat'] ?? obat['name'] ?? 'Obat').toString();
                    final qty = item['jumlah'] ?? 1;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          const Icon(Icons.fiber_manual_record, size: 6, color: AppColors.darkGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${qty}x',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()
                else
                  const Row(
                    children: [
                      Icon(Icons.medication_outlined, size: 16, color: Colors.black38),
                      SizedBox(width: 6),
                      Text(
                        'Pembelian Obat',
                        style: TextStyle(fontSize: 13, color: Colors.black54, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.black12, height: 1),
          ),

          // Row 4: Total & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Transaksi',
                    style: TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${controller.formatCurrency(total)}',
                    style: const TextStyle(
                      color: Color(0xFF4299E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (nextList.isNotEmpty)
                Row(
                  children: nextList.map((next) {
                    final isCancel = next == 'Dibatalkan';
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCancel ? const Color(0xFFfee2e2) : AppColors.darkGreen,
                          foregroundColor: isCancel ? const Color(0xFFef4444) : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: isCancel ? const BorderSide(color: Color(0xFFfca5a5), width: 1) : BorderSide.none,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => controller.ubahStatus(p, next, _apotekId),
                        child: Text(
                          next,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCancel ? const Color(0xFFb91c1c) : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ],
      ),
    ),);
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        bg = const Color(0xFFFFF9E6);
        fg = const Color(0xFFF1B404);
        text = 'Menunggu';
        break;
      case 'diproses':
        bg = const Color(0xFFE5EDE9);
        fg = const Color(0xFF3F5E53);
        text = 'Dikemas';
        break;
      case 'dikirim':
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFF57C00);
        text = 'Dikirim';
        break;
      case 'selesai':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF388E3C);
        text = 'Selesai';
        break;
      case 'dibatalkan':
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        text = 'Dibatalkan';
        break;
      default:
        bg = Colors.grey[100]!;
        fg = Colors.grey[700]!;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDeliveryStatus(String? status) {
    if (status == null) return '-';
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Kurir';
      case 'dikirim':
        return 'Sedang Dikirim';
      case 'sampai':
        return 'Tiba di Tujuan';
      default:
        return status;
    }
  }

  void _hubungiPelanggan(BuildContext context, Map<String, dynamic> order, AdminPesananController controller) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    final apotek = order['apotek'] ?? {};
    final idApotek = order['id_apotek'];
    final idAdmin = apotek['id_admin'];
    final userMap = order['users'] ?? {};
    final idCustomer = userMap['id_user'] ?? order['id_user'];
    final customerName = userMap['nama'] ?? order['nama_pemesan'] ?? 'Pelanggan';

    if (idApotek == null || idAdmin == null || idCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi chat tidak lengkap')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    final int userUidParsed = int.tryParse(idCustomer.toString()) ?? 0;
    final int idAdminParsed = int.tryParse(idAdmin.toString()) ?? 0;
    final int idApotekParsed = int.tryParse(idApotek.toString()) ?? 0;

    final chatId = await controller.createChatRoom(userUidParsed, idAdminParsed, idApotekParsed);

    if (context.mounted) {
      Navigator.pop(context); // Pop loading indicator
      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatId: chatId,
              roomName: customerName,
              idAdmin: idAdminParsed,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Gagal memulai chat'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
