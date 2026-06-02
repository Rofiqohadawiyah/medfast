import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'alamat_saya_page.dart';
import 'main_screen.dart';

class KeranjangPage extends StatefulWidget {
  const KeranjangPage({super.key});

  @override
  State<KeranjangPage> createState() => _KeranjangPageState();
}

class _KeranjangPageState extends State<KeranjangPage> {
  bool _isCheckingOut = false;
  String _paymentMethod = 'COD';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  Future<void> _prosesCheckout(CartProvider cartProvider, String userAddress) async {
    if (cartProvider.cartItems.isEmpty) return;

    setState(() => _isCheckingOut = true);

    try {
      final authService = AuthService();
      final token = await authService.token;

      // 1. Tentukan id_apotek (cari dari stok-obat atau default ke 1)
      int idApotek = 1;
      try {
        final firstItem = cartProvider.cartItems[0];
        final idObat = firstItem['id_obat'];
        
        final stockRes = await ApiClient.get('/stok-obat');
        if (stockRes.statusCode == 200) {
          final List<dynamic> stocks = jsonDecode(stockRes.body);
          final match = stocks.firstWhere(
            (s) => s['id_obat']?.toString() == idObat?.toString(),
            orElse: () => null,
          );
          if (match != null && match['id_apotek'] != null) {
            idApotek = (match['id_apotek'] as num).toInt();
          }
        }
      } catch (_) {}

      // 2. Buat detail items untuk pesanan
      final detailItems = cartProvider.cartItems.map((item) {
        final obat = item['obat'] as Map<String, dynamic>? ?? {};
        final price = (obat['harga'] ?? obat['price'] ?? 0) as num;
        return {
          'id_obat': item['id_obat'],
          'jumlah': item['jumlah'],
          'harga_satuan': price.toDouble(),
        };
      }).toList();

      final totalHarga = cartProvider.totalHarga + 10000; // Flat ongkir Rp 10.000

      // 3. Simpan Pesanan ke API
      final pesananRes = await ApiClient.post(
        '/pesanan',
        {
          'id_apotek': idApotek,
          'total_harga': totalHarga,
          'status_pesanan': 'menunggu',
          'detail_items': detailItems
        },
        token: token,
      );

      if (pesananRes.statusCode == 201) {
        final pesananData = jsonDecode(pesananRes.body);
        final idPesanan = pesananData['pesanan']['id_pesanan'];

        // 4. Simpan Pembayaran
        await ApiClient.post(
          '/pembayaran',
          {
            'id_pesanan': idPesanan,
            'metode_pembayaran': _paymentMethod,
            'status_pembayaran': 'belum_bayar',
          },
          token: token,
        );

        // 5. Simpan Pengiriman
        await ApiClient.post(
          '/pengiriman',
          {
            'id_pesanan': idPesanan,
            'alamat_tujuan': userAddress,
            'status_pengiriman': 'pending',
          },
          token: token,
        );

        // 6. Kosongkan keranjang belanja di database
        await cartProvider.clearCart();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan berhasil dibuat dari Keranjang!'), backgroundColor: AppColors.darkGreen),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)), // Pindah ke tab Pesanan
            (route) => false,
          );
        }
      } else {
        final errorMsg = jsonDecode(pesananRes.body)['message'] ?? 'Gagal memproses pesanan';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingOut = false);
      }
    }
  }

  void _showCheckoutDialog(CartProvider cartProvider, String userAddress) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalHarga = cartProvider.totalHarga;
          final ongkir = 10000.0;
          final grandTotal = totalHarga + ongkir;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Konfirmasi Checkout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alamat Pengiriman:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  userAddress,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const Divider(height: 24),
                
                // Metode Pembayaran
                const Text(
                  'Metode Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('COD (Bayar di Tempat)'),
                      selected: _paymentMethod == 'COD',
                      selectedColor: AppColors.lightGreen,
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _paymentMethod = 'COD');
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Transfer Bank'),
                      selected: _paymentMethod == 'Transfer',
                      selectedColor: AppColors.lightGreen,
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => _paymentMethod = 'Transfer');
                          setState(() {});
                        }
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Rincian Pembayaran
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal Produk', style: TextStyle(color: Colors.grey)),
                    Text('Rp ${totalHarga.toStringAsFixed(0)}'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Ongkos Kirim', style: TextStyle(color: Colors.grey)),
                    Text('Rp 10.000'),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Pembayaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Rp ${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.darkGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isCheckingOut
                        ? null
                        : () {
                            Navigator.pop(context); // Tutup bottomsheet
                            _prosesCheckout(cartProvider, userAddress);
                          },
                    child: _isCheckingOut
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Buat Pesanan',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;
    final address = user?.alamat ?? '';
    final hasAddress = address.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 24),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Keranjang Belanja',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Alamat Warning Header
          if (!hasAddress)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Alamat pengiriman belum diatur! Atur terlebih dahulu untuk bisa checkout.',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AlamatSayaPage()));
                    },
                    child: const Text('Atur', style: TextStyle(fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),

          // List Items
          Expanded(
            child: cartProvider.isLoading && cartProvider.cartItems.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : cartProvider.cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text(
                              'Keranjang belanja Anda kosong',
                              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => cartProvider.fetchCart(),
                        color: AppColors.darkGreen,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: cartProvider.cartItems.length,
                          itemBuilder: (context, index) {
                            final item = cartProvider.cartItems[index];
                            final obat = item['obat'] as Map<String, dynamic>? ?? {};
                            final idKeranjang = (item['id_keranjang'] as num).toInt();
                            
                            final name = (obat['nama_obat'] ?? obat['name'] ?? 'Nama Obat').toString();
                            final price = (obat['harga'] ?? obat['price'] ?? 0) as num;
                            final image = (obat['gambar'] ?? obat['image'] ?? '').toString();
                            final qty = (item['jumlah'] as num? ?? 1).toInt();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Product image
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: image.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(image, fit: BoxFit.cover),
                                          )
                                        : const Icon(Icons.medication, size: 36, color: AppColors.darkGreen),
                                  ),
                                  const SizedBox(width: 14),

                                  // Name, Price & Controls
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Rp ${price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                color: AppColors.darkGreen,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            (() {
                                              final stock = (obat['jumlah_stok'] ?? obat['stock'] ?? 0) as num;
                                              if (stock <= 0) {
                                                return const Text(
                                                  'Stok Habis',
                                                  style: TextStyle(
                                                    color: Colors.redAccent,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              }
                                              return Text(
                                                'Stok: $stock',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              );
                                            })(),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Quantity Controls
                                        Row(
                                          children: [
                                            // Minus Button
                                            GestureDetector(
                                              onTap: qty > 1
                                                  ? () => cartProvider.updateQuantity(idKeranjang, qty - 1)
                                                  : null,
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color: qty > 1 ? Colors.black87 : Colors.grey.shade400,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              qty.toString(),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(width: 12),
                                            // Plus Button
                                            GestureDetector(
                                              onTap: () => cartProvider.updateQuantity(idKeranjang, qty + 1),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.add, size: 16, color: Colors.black87),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text('Hapus Barang?'),
                                          content: const Text('Apakah Anda yakin ingin menghapus barang ini dari keranjang?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Batal'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                cartProvider.deleteItem(idKeranjang);
                                              },
                                              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // Total & Checkout Footer
          if (cartProvider.cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total Harga:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rp ${cartProvider.totalHarga.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      height: 52,
                      width: 140,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.darkGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: !hasAddress || _isCheckingOut
                            ? null
                            : () {
                                // Periksa ketersediaan stok untuk semua barang di keranjang
                                for (var item in cartProvider.cartItems) {
                                  final obat = item['obat'] as Map<String, dynamic>? ?? {};
                                  final name = (obat['nama_obat'] ?? obat['name'] ?? 'Obat').toString();
                                  final stock = (obat['jumlah_stok'] ?? obat['stock'] ?? 0) as num;
                                  final qty = (item['jumlah'] as num? ?? 1).toInt();

                                  if (stock <= 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Stok obat "$name" habis! Silakan hapus dari keranjang.'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }
                                  if (qty > stock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Jumlah pembelian "$name" melebihi stok yang tersedia ($stock)!'),
                                        backgroundColor: Colors.redAccent,
                                      ),
                                    );
                                    return;
                                  }
                                }
                                _showCheckoutDialog(cartProvider, address);
                              },
                        child: const Text(
                          'Checkout',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
