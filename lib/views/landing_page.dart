import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/landing_controller.dart';
import '../utils/colors.dart';
import 'product_detail_page.dart';
import 'main_screen.dart';
import 'apotek_page.dart';
import 'alamat_saya_page.dart';
import 'keranjang_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LandingController(),
      child: const _LandingPageUI(),
    );
  }
}

class _LandingPageUI extends StatelessWidget {
  const _LandingPageUI({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LandingController>();

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // HEADER HIJAU (Sesuai Figma)
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
                  // Lokasi (dinamis dari GPS)
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.white, size: 18),
                      const SizedBox(width: 4),
                      if (controller.locationLoading)
                        const SizedBox(
                          width: 12, height: 12,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      else
                        Text(
                          controller.locationName,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          controller.fetchLocation();
                        },
                        child: const Icon(Icons.refresh, color: Colors.white60, size: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MedFast',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KeranjangPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const Text(
                    'Pesan obat dan cari apotek terdekat dengan cepat',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  // SEARCH BAR
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      onChanged: controller.onSearchChanged,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.black26),
                        hintText: 'Cari obat...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CATEGORY FEATURE GRID (Shopee-Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCategoryItem(
                    context,
                    icon: Icons.map_outlined,
                    color: AppColors.darkGreen,
                    label: 'Peta Apotek',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApotekPage()),
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    color: const Color(0xFFEE4D2D), // Shopee Orange
                    label: 'Chat Admin',
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                        (route) => false,
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.shopping_bag_outlined,
                    color: Colors.blueAccent,
                    label: 'Pesanan Saya',
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                        (route) => false,
                      );
                    },
                  ),
                  _buildCategoryItem(
                    context,
                    icon: Icons.location_on_outlined,
                    color: Colors.redAccent,
                    label: 'Alamat Saya',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AlamatSayaPage()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // REKOMENDASI SECTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rekomendasi',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text('Lihat Semua', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PRODUCT GRID (Using Controller)
            Builder(
              builder: (context) {
                if (controller.productsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(controller.errorMessage!),
                    ),
                  );
                }

                if (controller.filteredProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('Obat tidak ditemukan'),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: controller.filteredProducts.length,
                  itemBuilder: (context, index) {
                    var data = controller.filteredProducts[index] as Map<String, dynamic>;
                    return _buildProductCard(context, data, controller.productApotekMap);
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context, 
    Map<String, dynamic> product,
    Map<String, Map<String, dynamic>> productApotekMap,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Image.network(
                  product['gambar'] ?? product['imageUrl'] ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, size: 50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['nama_obat'] ?? product['name'] ?? 'Obat',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                   Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      (() {
                        final idObat = (product['id_obat'] ?? product['id'] ?? '').toString();
                        final apotek = productApotekMap[idObat];
                        final String locationLabel;
                        if (apotek != null) {
                          final alamat = apotek['alamat']?.toString() ?? '';
                          if (alamat.isNotEmpty && alamat != '-') {
                            final parts = alamat.split(',');
                            locationLabel = parts[0].trim();
                          } else {
                            locationLabel = apotek['nama_apotek']?.toString() ?? 'Apotek Mitra';
                          }
                        } else {
                          locationLabel = '-';
                        }
                        return Expanded(
                          child: Text(
                            ' $locationLabel',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      })(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${product['harga'] ?? product['price'] ?? 0}',
                        style: const TextStyle(
                          color: Color(0xFF4299E1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (product['jumlah_stok'] != null || product['stock'] != null)
                        Text(
                          'Stok: ${product['jumlah_stok'] ?? product['stock']}',
                          style: const TextStyle(
                            color: Colors.black45,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}