import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../controllers/product_detail_controller.dart';
import '../utils/colors.dart';
import 'alamat_saya_page.dart';
import 'main_screen.dart';
import 'apotek_detail_page.dart';
import 'payment_webview_page.dart';

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final user = Provider.of<AuthProvider>(context, listen: false).userModel;
        final address = user?.alamat ?? '';
        final targetId = product['id_obat'] ?? product['id'];
        return ProductDetailController()..fetchApotekInfo(targetId, address);
      },
      child: _ProductDetailPageUI(product: product),
    );
  }
}

class _ProductDetailPageUI extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductDetailPageUI({required this.product});

  Future<void> _tambahKeKeranjang(BuildContext context) async {
    final idObat = product['id_obat'] ?? product['id'];
    if (idObat == null) return;

    final idObatInt = int.tryParse(idObat.toString()) ?? 0;
    if (idObatInt == 0) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.darkGreen),
      ),
    );

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final success = await cartProvider.addToCart(idObatInt, 1);

      if (context.mounted) {
        Navigator.pop(context); // Tutup dialog loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obat berhasil dimasukkan ke keranjang!'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambah ke keranjang: ${cartProvider.errorMessage}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductDetailController>();
    final price = product['harga'] ?? product['price'] ?? 0;
    final imageUrl = product['gambar'] ?? product['imageUrl'] ?? 'https://via.placeholder.com/300';
    final name = product['nama_obat'] ?? product['name'] ?? 'Nama Obat';
    final desc = product['deskripsi'] ?? product['description'] ?? 'Belum ada deskripsi untuk produk ini.';

    final stockVal = product['jumlah_stok'] ?? product['stock'];
    final stock = stockVal != null ? (int.tryParse(stockVal.toString()) ?? 0) : null;
    final isOutOfStock = stock != null && stock <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Obat & Back Button
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 320,
                      color: const Color(0xFFEFEFEF),
                      child: const Icon(Icons.medication, size: 100, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info Block
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Text('Rp $price', style: const TextStyle(fontSize: 26, color: AppColors.darkGreen, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.darkGreen),
                          ),
                          child: const Text('Pilihan Terbaik', style: TextStyle(color: AppColors.darkGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Garansi 100% Asli', style: TextStyle(color: Colors.black45, fontSize: 12)),
                        const Spacer(),
                        if (stock != null)
                          Text(
                            'Stok: $stock',
                            style: const TextStyle(color: Color(0xFFEE4D2D), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Description Block
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Deskripsi Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 12),
                    Text(desc, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Apotek Profile Card
              GestureDetector(
                onTap: controller.isLoadingApotek
                    ? null
                    : () {
                        final apotekData = <String, dynamic>{
                          'id_apotek': controller.idApotek,
                          'nama_apotek': controller.namaApotek,
                          'alamat': controller.alamatApotek,
                          'jam_operasional': controller.jamOperasional,
                          'no_hp': controller.noHpApotek,
                          'latitude': controller.apotekLat,
                          'longitude': controller.apotekLng,
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ApotekDetailPage(apotek: apotekData)),
                        );
                      },
                child: Container(
                  color: Colors.white,
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: controller.isLoadingApotek
                      ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16), child: CircularProgressIndicator(color: AppColors.darkGreen)))
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundColor: AppColors.lightGreen,
                              child: const Icon(Icons.store, color: AppColors.darkGreen, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(controller.namaApotek, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                                      ),
                                      const SizedBox(width: 8),
                                      (() {
                                        final isOpen = controller.isApotekOpen();
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: isOpen ? const Color(0xFF81C784) : const Color(0xFFBDBDBD), width: 0.5),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 8, height: 8,
                                                decoration: BoxDecoration(color: isOpen ? const Color(0xFF4CAF50) : const Color(0xFF9E9E9E), shape: BoxShape.circle),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(isOpen ? 'Buka' : 'Tutup', style: TextStyle(color: isOpen ? const Color(0xFF2E7D32) : const Color(0xFF616161), fontSize: 11, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        );
                                      })(),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(controller.alamatApotek, style: const TextStyle(color: Colors.black54, fontSize: 15, height: 1.4)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on, size: 16, color: AppColors.darkGreen),
                                      const SizedBox(width: 4),
                                      controller.isCalculatingDistance
                                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.darkGreen))
                                          : Text('${controller.distanceInKm.toStringAsFixed(1)} km dari lokasi Anda', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGreen)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(4), border: Border.all(color: AppColors.darkGreen)),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkGreen),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)), (route) => false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: controller.isLoadingApotek || isOutOfStock ? Colors.grey[200] : AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: controller.isLoadingApotek || isOutOfStock ? Colors.grey : AppColors.darkGreen),
                ),
                child: IconButton(
                  icon: Icon(Icons.add_shopping_cart, color: controller.isLoadingApotek || isOutOfStock ? Colors.grey : AppColors.darkGreen),
                  onPressed: (controller.isLoadingApotek || isOutOfStock) ? null : () => _tambahKeKeranjang(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey : AppColors.darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: (controller.isLoadingApotek || isOutOfStock)
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => ChangeNotifierProvider.value(
                                value: controller,
                                child: _CheckoutSheet(product: product),
                              ),
                            );
                          },
                    child: Text(isOutOfStock ? 'Stok Habis' : 'Beli Sekarang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSheet extends StatelessWidget {
  final Map<String, dynamic> product;

  const _CheckoutSheet({required this.product});

  void _handleCheckoutResult(BuildContext context, Map<String, dynamic> result) {
    if (result['success'] == true) {
      if (result['method'] == 'Midtrans') {
        final paymentUrl = result['payment_url'];
        final idPesanan = result['idPesanan'];
        if (paymentUrl != null) {
          Navigator.pop(context); // Close sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentWebviewPage(paymentUrl: paymentUrl, idPesanan: idPesanan),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pesanan dibuat! Silakan bayar dari halaman Pesanan.'), backgroundColor: AppColors.darkGreen),
          );
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)), (route) => false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: AppColors.darkGreen),
        );
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)), (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${result['error']}'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductDetailController>();
    final user = Provider.of<AuthProvider>(context).userModel;
    final address = user?.alamat ?? '';
    final hasAddress = address.trim().isNotEmpty;

    final price = product['harga'] ?? product['price'] ?? 0;
    final name = product['nama_obat'] ?? product['name'] ?? 'Nama Obat';
    final productSubtotal = price * controller.quantity;
    
    final shippingFee = (controller.distanceInKm * 4000).round();
    final coinDiscount = controller.useCoins ? 1000 : 0;
    final grandTotal = productSubtotal + shippingFee - coinDiscount;

    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF5F5F5), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Konfirmasi Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, color: Colors.black45))
              ],
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: AppColors.darkGreen, size: 20),
                            SizedBox(width: 8),
                            Text('Alamat Pengiriman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hasAddress)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.darkGreen.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(child: Text('Alamat belum diatur! Anda wajib mengatur alamat pengiriman terlebih dahulu.', style: TextStyle(color: AppColors.darkGreen, fontSize: 13))),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.darkGreen, side: const BorderSide(color: AppColors.darkGreen), padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlamatSayaPage()));
                                  },
                                  child: const Text('Atur', style: TextStyle(fontSize: 12)),
                                )
                              ],
                            ),
                          )
                        else ...[
                          Text(user?.name ?? 'Nama Pelanggan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(address, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.store, color: Colors.black54, size: 18),
                            const SizedBox(width: 8),
                            Text(controller.namaApotek, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Mitra', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70, height: 70,
                              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(4)),
                              child: product['gambar'] != null ? Image.network(product['gambar'], fit: BoxFit.cover) : const Icon(Icons.medication, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 8),
                                  Text('Rp $price', style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: controller.decrementQuantity,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: const BorderRadius.horizontal(left: Radius.circular(2))),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.black54),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(border: Border.symmetric(vertical: BorderSide(color: Colors.grey[300]!))),
                                  child: Text('${controller.quantity}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                GestureDetector(
                                  onTap: controller.incrementQuantity,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: const BorderRadius.horizontal(right: Radius.circular(2))),
                                    child: const Icon(Icons.add, size: 14, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Opsi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('Reguler (Rp $shippingFee)', style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimasi tiba dalam 1 - 2 jam', style: TextStyle(color: Colors.black45, fontSize: 12)),
                            Text('Jarak: ${controller.distanceInKm.toStringAsFixed(1)} km (Rp 4.000 / km)', style: const TextStyle(color: Colors.black45, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('Tukarkan 1.000 Koin MedFast', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Switch(
                          value: controller.useCoins,
                          activeColor: AppColors.darkGreen,
                          onChanged: controller.setUseCoins,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12, runSpacing: 12,
                          children: [
                            GestureDetector(
                              onTap: () => controller.setPaymentMethod('COD'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: controller.paymentMethod == 'COD' ? AppColors.lightGreen.withValues(alpha: 0.4) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: controller.paymentMethod == 'COD' ? AppColors.darkGreen : Colors.grey[300]!, width: 1.5),
                                ),
                                child: Text('COD (Bayar di Tempat)', style: TextStyle(color: controller.paymentMethod == 'COD' ? AppColors.darkGreen : Colors.black87, fontWeight: controller.paymentMethod == 'COD' ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.setPaymentMethod('Midtrans'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: controller.paymentMethod == 'Midtrans' ? const Color(0xFFDFECE7) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: controller.paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.grey[300]!, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payment, size: 14, color: controller.paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.black87),
                                    const SizedBox(width: 4),
                                    Text('Bayar Online', style: TextStyle(color: controller.paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.black87, fontWeight: controller.paymentMethod == 'Midtrans' ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal untuk Produk', style: TextStyle(color: Colors.black54, fontSize: 13)), Text('Rp $productSubtotal', style: const TextStyle(fontSize: 13))]),
                        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal Pengiriman', style: TextStyle(color: Colors.black54, fontSize: 13)), Text('Rp $shippingFee', style: const TextStyle(fontSize: 13))]),
                        if (controller.useCoins) ...[
                          const SizedBox(height: 6),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: const [Text('Diskon Koin MedFast', style: TextStyle(color: Colors.black54, fontSize: 13)), Text('-Rp 1.000', style: TextStyle(color: AppColors.darkGreen, fontSize: 13))]),
                        ],
                        const SizedBox(height: 12),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), Text('Rp $grandTotal', style: const TextStyle(color: AppColors.darkGreen, fontSize: 17, fontWeight: FontWeight.bold))]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          Container(
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(color: Colors.black54, fontSize: 11)),
                        Text('Rp $grandTotal', style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 46, width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.darkGreen, disabledBackgroundColor: Colors.grey[300], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                      onPressed: (!hasAddress || controller.isSubmitting)
                          ? null
                          : () async {
                              final result = await controller.submitDirectCheckout(
                                product: product,
                                address: address,
                                shippingFee: shippingFee,
                              );
                              if (context.mounted) {
                                _handleCheckoutResult(context, result);
                              }
                            },
                      child: controller.isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Buat Pesanan', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
