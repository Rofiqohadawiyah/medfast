import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class PesananPage extends StatefulWidget {
  const PesananPage({super.key});

  @override
  State<PesananPage> createState() => _PesananPageState();
}

class _PesananPageState extends State<PesananPage> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    try {
      final rawUrl = ApiClient.baseUrl;
      final socketUrl = rawUrl.substring(0, rawUrl.lastIndexOf('/api'));

      debugPrint('Initializing Customer Order Socket with URL: $socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('Customer Order Socket connected successfully');
        final user = Provider.of<AuthProvider>(context, listen: false).userModel;
        if (user != null) {
          debugPrint('Customer Order Socket: Joining orders updates for user ${user.uid}');
          _socket!.emit('join_orders_updates', user.uid);
        } else {
          debugPrint('Customer Order Socket: userModel is null');
        }
      });

      _socket!.onConnectError((err) {
        debugPrint('Customer Order Socket connection error: $err');
      });

      _socket!.onError((err) {
        debugPrint('Customer Order Socket error: $err');
      });

      _socket!.on('order_status_updated', (data) {
        debugPrint('Order status updated event received: $data');
        _fetchOrders();
      });

      _socket!.onDisconnect((_) {
        debugPrint('Customer Order Socket disconnected');
      });
    } catch (e) {
      debugPrint('Error order socket init: $e');
    }
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/pesanan', token: token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _orders = data;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal mengambil data pesanan');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _cancelOrder(int idPesanan) async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put(
        '/pesanan/$idPesanan',
        {'status_pesanan': 'dibatalkan'},
        token: token,
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibatalkan'), backgroundColor: AppColors.darkGreen),
          );
        }
        _fetchOrders();
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Gagal membatalkan pesanan';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) async {
    final idPesanan = order['id_pesanan'];
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/pesanan/$idPesanan', token: token);
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
      }

      if (response.statusCode == 200) {
        final orderDetail = jsonDecode(response.body);
        if (mounted) {
          _showDetailBottomSheet(orderDetail);
        }
      } else {
        throw Exception('Gagal mengambil detail pesanan');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading if still showing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showDetailBottomSheet(Map<String, dynamic> detail) {
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
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                            Navigator.pop(context); // close sheet
                            _confirmCancelDialog(detail['id_pesanan']);
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
                          Navigator.pop(context);
                          _hubungiApotek(detail);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                        label: const Text('Chat Apotek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancelDialog(int idPesanan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tidak')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(idPesanan);
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _hubungiApotek(Map<String, dynamic> order) async {
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

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post(
        '/chat/room',
        {
          'id_pelanggan': int.parse(user.uid),
          'id_admin': idAdmin,
          'id_apotek': idApotek,
        },
        token: token,
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading indicator
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        final chatId = room['id_chat'];

        if (mounted) {
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
        }
      } else {
        throw Exception('Gagal membuat room chat');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading if still active
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai chat: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Riwayat Pesanan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.darkGreen,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
          : _orders.isEmpty
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
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    final apotek = order['apotek'] ?? {};
                    final status = order['status_pesanan'] ?? 'menunggu';

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        onTap: () => _showOrderDetail(order),
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
