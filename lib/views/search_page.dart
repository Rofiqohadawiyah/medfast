import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/search_controller.dart' as ctrl;
import '../utils/colors.dart';
import 'product_detail_page.dart';

class SearchPage extends StatelessWidget {
  final int selectedTab;

  const SearchPage({
    super.key,
    this.selectedTab = 0,
  });

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final addressStr = user?.alamat?.toString() ?? '';

    return ChangeNotifierProvider(
      create: (_) => ctrl.SearchController()..initData(addressStr),
      child: const _SearchPageUI(),
    );
  }
}

class _SearchPageUI extends StatefulWidget {
  const _SearchPageUI({super.key});

  @override
  State<_SearchPageUI> createState() => _SearchPageUIState();
}

class _SearchPageUIState extends State<_SearchPageUI> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ctrl.SearchController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context, controller),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  controller.searchQuery.isNotEmpty ? 'Hasil Pencarian Obat' : 'Rekomendasi Obat Terdekat',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: controller.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.darkGreen),
                        ),
                      )
                    : controller.filteredMedicines.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Tidak ada obat ditemukan.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          )
                        : GridView.builder(
                            itemCount: controller.filteredMedicines.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.62,
                            ),
                            itemBuilder: (context, index) {
                              final item = controller.filteredMedicines[index];
                              final name = item['nama_obat'] ?? item['name'] ?? 'Nama Obat';
                              final rawPrice = item['harga'] ?? item['price'] ?? 0;
                              final price = 'Rp ${rawPrice.toString()}';
                              final image = item['gambar'] ?? item['imageUrl'] ?? '';

                              final distVal = item['closest_distance'] as double?;
                              final apotekName = item['closest_apotek_name'] ?? 'Apotek Terdekat';


                              final locationText = distVal != null
                                  ? '$apotekName\n(${distVal.toStringAsFixed(1)} km)'
                                  : (item['jumlah_stok'] == 0 || item['jumlah_stok'] == null
                                      ? 'Stok Habis'
                                      : apotekName);

                              return SearchProductCard(
                                name: name,
                                location: locationText,
                                price: price,
                                image: image,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ProductDetailPage(product: item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ctrl.SearchController controller) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final userAlamat = user?.alamat;
    final String addressText = (userAlamat != null && userAlamat.toString().isNotEmpty) ? userAlamat.toString() : 'Lokasi Anda';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: const Color(0xFFCFEAFF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 32),
              ),
              const Spacer(),
              const Icon(Icons.location_on_outlined, size: 22),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: controller.onSearchChanged,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari obat...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                if (controller.searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      controller.onSearchChanged('');
                    },
                    child: const Icon(Icons.clear, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchProductCard extends StatelessWidget {
  final String name;
  final String location;
  final String price;
  final String image;
  final VoidCallback? onTap;

  const SearchProductCard({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = image.startsWith('http://') || image.startsWith('https://');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEF8),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 74,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: isNetworkImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.medication,
                            size: 36,
                            color: AppColors.darkGreen,
                          ),
                        ),
                      )
                    : (image.isNotEmpty
                        ? Image.asset(
                            image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.medication,
                              size: 36,
                              color: AppColors.darkGreen,
                            ),
                          )
                        : const Icon(
                            Icons.medication,
                            size: 36,
                            color: AppColors.darkGreen,
                          )),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    location,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Text(
                price,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1E88E5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
