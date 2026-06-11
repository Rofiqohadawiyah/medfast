import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/pesanan_controller.dart';
import '../services/payment_service.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'payment_webview_page.dart';

class PesananPage extends StatelessWidget {
  const PesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PesananController(),
      child: const _PesananPageUI(),
    );
  }
}

class _PesananPageUI extends StatefulWidget {
  const _PesananPageUI({super.key});

  @override
  State<_PesananPageUI> createState() => _PesananPageUIState();
}

class _PesananPageUIState extends State<_PesananPageUI> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final controller = context.read<PesananController>();
      controller.initSocket(user?.uid);
      controller.fetchOrders();
    });
  }

  @override
  void dispose() {
    Future.microtask(() {
      if (mounted) {
        context.read<PesananController>().disposeSocket();
      }
    });
    super.dispose();
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> order) async {
    final controller = context.read<PesananController>();
    final idPesanan = order['id_pesanan'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    final detail = await controller.fetchOrderDetail(idPesanan);

    if (context.mounted) {
      Navigator.pop(context); // Pop loading dialog
      
      if (detail != null) {
        _showDetailBottomSheet(context, detail, controller);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? 'Gagal mengambil detail pesanan'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDetailBottomSheet(BuildContext context, Map<String, dynamic> detail, PesananController controller) {
    final apotek = detail['apotek'] ?? {};
    final detailItems = detail['detail_pesanan'] ?? [];
    final Map<String, dynamic> pembayaran = (detail['pembayaran'] is List && (detail['pembayaran'] as List).isNotEmpty)
        ? (detail['pembayaran'][0] as Map<String, dynamic>? ?? {})
        : (detail['pembayaran'] is Map ? (detail['pembayaran'] as Map<String, dynamic>) : {});
    final Map<String, dynamic> pengiriman = (detail['pengiriman'] is List && (detail['pengiriman'] as List).isNotEmpty)
        ? (detail['pengiriman'][0] as Map<String, dynamic>? ?? {})
        : (detail['pengiriman'] is Map ? (detail['pengiriman'] as Map<String, dynamic>) : {});
    final status = detail['status_pesanan'] ?? 'menunggu';

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
                Text('Apotek: ${apotek['nama_apotek'] ?? 'Apotek'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Text('Tanggal: ${_formatDate(detail['tanggal_pesanan'])}', style: const TextStyle(color: Colors.black54)),
                const Divider(height: 32),

                // Item list
                const Text('Daftar Obat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...detailItems.map((item) {
                  final obat = item['obat'] ?? {};
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${obat['nama_obat'] ?? 'Obat'} (x${item['jumlah']})', style: const TextStyle(fontSize: 15)),
                        Text('Rp ${item['harga_satuan'] * item['jumlah']}', style: const TextStyle(fontWeight: FontWeight.w600)),
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
                    Text(pembayaran['metode_pembayaran'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Pembayaran', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    Text(
                      pembayaran['status_pembayaran'] == 'lunas' ? 'Lunas' : 'Belum Bayar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: pembayaran['status_pembayaran'] == 'lunas' ? Colors.green : Colors.orange,
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
                  child: Text(pengiriman['alamat_tujuan'] ?? '-', style: const TextStyle(fontSize: 13)),
                ),
                const Divider(height: 32),

                // Grand Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Pembayaran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Rp ${detail['total_harga']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkGreen)),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                Row(
                  children: [
                    if (status == 'pending' || status == 'menunggu') ...[
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            Navigator.pop(sheetContext); // close sheet
                            _confirmCancelDialog(context, detail['id_pesanan'], controller);
                          },
                          child: const Text('Batalkan'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _hubungiApotek(context, detail, controller);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        label: const Text('Chat Apotek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tombol Bayar Sekarang (jika metode Midtrans & belum bayar)
                if (pembayaran['metode_pembayaran'] == 'Midtrans' &&
                    pembayaran['status_pembayaran'] != 'lunas')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F5E53),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.pop(sheetContext); // tutup bottom sheet
                        final paymentService = PaymentService();
                        final snapData = await paymentService.getSnapToken(detail['id_pesanan']);
                        if (context.mounted) {
                          if (snapData != null && snapData['payment_url'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentWebviewPage(
                                  paymentUrl: snapData['payment_url'],
                                  idPesanan: detail['id_pesanan'],
                                  onSuccess: controller.fetchOrders,
                                  onFailure: controller.fetchOrders,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mendapatkan link pembayaran'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.payment, color: Colors.white),
                      label: const Text('Bayar Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancelDialog(BuildContext context, int idPesanan, PesananController controller) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tidak')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await controller.cancelOrder(idPesanan);
              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pesanan berhasil dibatalkan'), backgroundColor: AppColors.darkGreen),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(controller.errorMessage ?? 'Gagal membatalkan pesanan'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _hubungiApotek(BuildContext context, Map<String, dynamic> order, PesananController controller) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    final apotek = order['apotek'] ?? {};
    final idApotek = order['id_apotek'];
    final idAdmin = apotek['id_admin'];
    final apotekName = apotek['nama_apotek'] ?? 'Apotek';

    if (idApotek == null || idAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informasi Apotek tidak lengkap untuk chat')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    final chatId = await controller.createChatRoom(int.parse(user.uid), idAdmin, idApotek);

    if (context.mounted) {
      Navigator.pop(context); // Pop loading indicator
      if (chatId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatId: chatId,
              roomName: apotekName,
              idAdmin: idAdmin,
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PesananController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Riwayat Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkGreen,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: controller.fetchOrders,
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
          : controller.orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.black26),
                      SizedBox(height: 16),
                      Text('Belum ada pesanan', style: TextStyle(fontSize: 16, color: Colors.black45)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = controller.orders[index];
                    final apotek = order['apotek'] ?? {};
                    final status = order['status_pesanan'] ?? 'menunggu';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        onTap: () => _showOrderDetail(context, order),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      apotek['nama_apotek'] ?? 'Apotek',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  _buildStatusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(order['tanggal_pesanan']),
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Pembayaran', style: TextStyle(color: Colors.black54)),
                                  Text(
                                    'Rp ${order['total_harga']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 15),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String text;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        bg = Colors.amber[50]!;
        fg = Colors.amber[800]!;
        text = 'Menunggu';
        break;
      case 'diproses':
        bg = Colors.blue[50]!;
        fg = Colors.blue[800]!;
        text = 'Diproses';
        break;
      case 'dikirim':
        bg = Colors.orange[50]!;
        fg = Colors.orange[800]!;
        text = 'Dikirim';
        break;
      case 'selesai':
        bg = Colors.green[50]!;
        fg = Colors.green[800]!;
        text = 'Selesai';
        break;
      case 'dibatalkan':
        bg = Colors.red[50]!;
        fg = Colors.red[800]!;
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

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      String cleanStr = isoString.trim();
      if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && !cleanStr.contains(RegExp(r'-\d{2}:\d{2}'))) {
        cleanStr = cleanStr.replaceAll(' ', 'T');
        cleanStr = '${cleanStr}Z';
      }
      final date = DateTime.parse(cleanStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoString;
    }
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
}
