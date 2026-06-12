import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../controllers/pesanan_controller.dart';
import '../services/payment_service.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'chat_rooms_page.dart';
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
  String _selectedTab = 'aktif'; // 'aktif', 'riwayat', 'dibatalkan'

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

  void _beliLagi(BuildContext context, Map<String, dynamic> order) async {
    final controller = context.read<PesananController>();
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final idPesanan = order['id_pesanan'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    final detail = await controller.fetchOrderDetail(idPesanan);
    if (context.mounted) {
      Navigator.pop(context); // Pop loading dialog
    }

    if (detail == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memproses pembelian ulang'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    final detailItems = detail['detail_pesanan'] ?? [];
    if (detailItems.isEmpty) return;

    bool allSuccess = true;
    for (var item in detailItems) {
      final obat = item['obat'] ?? {};
      final idObat = obat['id_obat'];
      final qty = (item['jumlah'] as num? ?? 1).toInt();
      if (idObat != null) {
        final idObatInt = int.tryParse(idObat.toString()) ?? 0;
        if (idObatInt != 0) {
          final success = await cartProvider.addToCart(idObatInt, qty);
          if (!success) allSuccess = false;
        }
      }
    }

    if (context.mounted) {
      if (allSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua produk berhasil dimasukkan kembali ke keranjang!'),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beberapa produk gagal dimasukkan ke keranjang'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTabItem('Sedang Berjalan', 'aktif'),
            const SizedBox(width: 8),
            _buildTabItem('Riwayat', 'riwayat'),
            const SizedBox(width: 8),
            _buildTabItem('Dibatalkan', 'dibatalkan'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String label, String tabKey) {
    final isActive = _selectedTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF3F5E53) : const Color(0xFFE5EDE9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF3F5E53),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pesanan',
            style: TextStyle(fontSize: 16, color: Colors.black45, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Map<String, dynamic> order) {
    final apotek = order['apotek'] ?? {};
    final status = order['status_pesanan'] ?? 'menunggu';
    final detailItems = order['detail_pesanan'] as List? ?? [];
    
    final hasItems = detailItems.isNotEmpty;
    final firstItem = hasItems ? detailItems.first : null;
    final firstObat = firstItem?['obat'] ?? {};
    final firstImage = (firstObat['gambar'] ?? firstObat['image'] ?? '').toString();
    
    String productText = '';
    if (hasItems) {
      final firstName = (firstObat['nama_obat'] ?? firstObat['name'] ?? 'Obat').toString();
      if (detailItems.length > 1) {
        productText = '$firstName, ...';
      } else {
        productText = firstName;
      }
    } else {
      productText = 'Pembelian Obat';
    }

    final totalCountText = hasItems ? '${detailItems.length} Produk' : 'Produk';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Apotek Icon, Name, Date and Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5EDE9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_outlined, color: AppColors.darkGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apotek['nama_apotek'] ?? 'Apotek',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(order['tanggal_pesanan']),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusBadge(status),
            ],
          ),
          
          const Divider(height: 24, thickness: 0.8),

          // Row 2: Product info
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFDFECE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: firstImage.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(firstImage, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.medication_outlined, color: AppColors.darkGreen, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productText,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCountText,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 24, thickness: 0.8),

          // Row 3: Total & Action Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pesanan',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Rp ${order['total_harga']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGreen,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              _buildActionButton(context, order),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> order) {
    final status = (order['status_pesanan'] ?? 'menunggu').toString().toLowerCase();
    
    if (status == 'selesai') {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkGreen,
          side: const BorderSide(color: AppColors.darkGreen, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          minimumSize: const Size(100, 36),
        ),
        onPressed: () => _beliLagi(context, order),
        child: const Text('Beli Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
    } else {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3F5E53),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          minimumSize: const Size(100, 36),
          elevation: 0,
        ),
        onPressed: () => _showOrderDetail(context, order),
        child: const Text('Detail', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PesananController>();

    final filteredOrders = controller.orders.where((order) {
      final status = (order['status_pesanan'] ?? 'menunggu').toString().toLowerCase();
      if (_selectedTab == 'aktif') {
        return status == 'pending' || status == 'menunggu' || status == 'diproses' || status == 'dikirim';
      } else if (_selectedTab == 'riwayat') {
        return status == 'selesai';
      } else {
        return status == 'dibatalkan';
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header Banner
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (Navigator.canPop(context))
                  Positioned(
                    left: 8,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                const Text(
                  'Pesanan Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Positioned(
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatRoomsPage()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tab Selector
          _buildTabSelector(),

          // Body Content
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => controller.fetchOrders(),
                        color: AppColors.darkGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            return _buildOrderCard(context, filteredOrders[index]);
                          },
                        ),
                      ),
          ),
        ],
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

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      String cleanStr = isoString.trim();
      if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && !cleanStr.contains(RegExp(r'-\d{2}:\d{2}'))) {
        cleanStr = cleanStr.replaceAll(' ', 'T');
        cleanStr = '${cleanStr}Z';
      }
      final date = DateTime.parse(cleanStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day} ${months[date.month - 1]} ${date.year} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
