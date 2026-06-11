import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/keranjang_controller.dart';
import '../utils/colors.dart';
import 'alamat_saya_page.dart';
import 'main_screen.dart';
import 'payment_webview_page.dart';

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => KeranjangController(),
      child: const _KeranjangPageUI(),
    );
  }
}

class _KeranjangPageUI extends StatefulWidget {
  const _KeranjangPageUI({super.key});

  @override
  State<_KeranjangPageUI> createState() => _KeranjangPageUIState();
}

class _KeranjangPageUIState extends State<_KeranjangPageUI> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<CartProvider>(context, listen: false).fetchCart();
    });
  }

  void _handleCheckoutResult(BuildContext context, Map<String, dynamic>? result) {
    if (result == null) return;

    if (result['success'] == true) {
      if (result['method'] == 'Midtrans') {
        final paymentUrl = result['payment_url'];
        final idPesanan = result['idPesanan'];
        
        if (paymentUrl != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebviewPage(
                paymentUrl: paymentUrl,
                idPesanan: idPesanan,
                onSuccess: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                    (route) => false,
                  );
                },
                onFailure: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                    (route) => false,
                  );
                },
              ),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan dibuat! Silakan bayar dari halaman Pesanan.'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: AppColors.darkGreen),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
          (route) => false,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showCheckoutDialog(BuildContext context, CartProvider cartProvider, String userAddress) {
    final controller = context.read<KeranjangController>();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<KeranjangController>(
          builder: (context, ctrl, child) {
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
                  const Text('Konfirmasi Checkout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Alamat Pengiriman:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(userAddress, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  const Divider(height: 24),
                  
                  // Metode Pembayaran
                  const Text('Metode Pembayaran:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('COD'),
                        selected: ctrl.paymentMethod == 'COD',
                        selectedColor: AppColors.lightGreen,
                        onSelected: (selected) {
                          if (selected) ctrl.setPaymentMethod('COD');
                        },
                      ),
                      ChoiceChip(
                        avatar: const Icon(Icons.payment, size: 16),
                        label: const Text('Bayar Online'),
                        selected: ctrl.paymentMethod == 'Midtrans',
                        selectedColor: const Color(0xFFDFECE7),
                        onSelected: (selected) {
                          if (selected) ctrl.setPaymentMethod('Midtrans');
                        },
                      ),
                    ],
                  ),
                  if (ctrl.paymentMethod == 'Midtrans')
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3F5E53).withOpacity(0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Color(0xFF3F5E53)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Bayar via GoPay, QRIS, Virtual Account, dan lainnya',
                              style: TextStyle(fontSize: 12, color: Color(0xFF3F5E53)),
                            ),
                          ),
                        ],
                      ),
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
                      const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                      onPressed: ctrl.isCheckingOut
                          ? null
                          : () async {
                              final currentContext = context;
                              Navigator.pop(sheetContext); // Tutup bottomsheet
                              
                              final result = await ctrl.prosesCheckout(
                                cartProvider: cartProvider, 
                                userAddress: userAddress
                              );
                              
                              if (currentContext.mounted) {
                                _handleCheckoutResult(currentContext, result);
                              }
                            },
                      child: ctrl.isCheckingOut
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = Provider.of<AuthProvider>(context).userModel;
    final address = user?.alamat ?? '';
    final hasAddress = address.trim().isNotEmpty;
    final controller = context.watch<KeranjangController>();

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
                        onPressed: !hasAddress || controller.isCheckingOut
                            ? null
                            : () {
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
                                _showCheckoutDialog(context, cartProvider, address);
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
