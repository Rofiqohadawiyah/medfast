import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../controllers/apotek_detail_controller.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'product_detail_page.dart';

class ApotekDetailPage extends StatelessWidget {
  final Map<String, dynamic> apotek;

  const ApotekDetailPage({super.key, required this.apotek});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApotekDetailController(),
      child: _ApotekDetailPageUI(apotek: apotek),
    );
  }
}

class _ApotekDetailPageUI extends StatefulWidget {
  final Map<String, dynamic> apotek;

  const _ApotekDetailPageUI({required this.apotek});

  @override
  State<_ApotekDetailPageUI> createState() => _ApotekDetailPageUIState();
}

class _ApotekDetailPageUIState extends State<_ApotekDetailPageUI> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final addressStr = user?.alamat?.toString() ?? '';
      context.read<ApotekDetailController>().loadLocationAndMedicines(widget.apotek, addressStr);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openGoogleMaps() async {
    final lat = (widget.apotek['latitude'] as num?)?.toDouble();
    final lng = (widget.apotek['longitude'] as num?)?.toDouble();
    final name = widget.apotek['nama_apotek'] ?? 'Apotek';
    if (lat == null || lng == null) return;

    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  void _hubungiApotek() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    final controller = context.read<ApotekDetailController>();
    final chatId = await controller.hubungiApotek(widget.apotek, user.uid);
    
    if (context.mounted) {
      if (chatId != null) {
        int? idAdmin = widget.apotek['id_admin'] != null
          ? (widget.apotek['id_admin'] as num).toInt()
          : null;
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              chatId: chatId,
              roomName: widget.apotek['nama_apotek'] ?? 'Apotek',
              idAdmin: idAdmin ?? 0, // Should be resolved in a real scenario
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Gagal memulai chat'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ApotekDetailController>();
    final name = widget.apotek['nama_apotek'] ?? widget.apotek['name'] ?? 'Apotek';
    final address = widget.apotek['alamat'] ?? widget.apotek['alamat_apotek'] ?? widget.apotek['address'] ?? '-';
    final jamOperasional = widget.apotek['jam_operasional'] ?? '-';
    final noHpRaw = widget.apotek['no_hp'] ?? widget.apotek['nomor_hp'] ?? widget.apotek['phone'];
    final noHpText = (noHpRaw != null && noHpRaw.toString().trim().isNotEmpty) ? noHpRaw.toString() : 'Nomor HP belum tersedia';
    final isOpen = controller.isApotekOpen(jamOperasional);

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: CustomScrollView(
        slivers: [
          // Banner & Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(offset: Offset(0, 2), blurRadius: 4, color: Colors.black45),
                  ],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkGreen, Color(0xFF2D3748)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.local_pharmacy_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
          ),

          // Apotek Details Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            isOpen ? 'BUKA' : 'TUTUP',
                            style: TextStyle(
                              color: isOpen ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (controller.distanceKm != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.directions_walk, size: 14, color: AppColors.darkGreen),
                                const SizedBox(width: 4),
                                Text(
                                  '${controller.distanceKm!.toStringAsFixed(1)} km',
                                  style: const TextStyle(
                                    color: AppColors.darkGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Alamat
                    const Text(
                      'Alamat',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Jam Operasional
                    const Text(
                      'Jam Operasional',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jamOperasional,
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                    ),
                    const SizedBox(height: 16),

                    // Nomor HP
                    const Text(
                      'Nomor HP',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      noHpText,
                      style: TextStyle(
                        fontSize: 15, 
                        color: noHpText == 'Nomor HP belum tersedia' ? Colors.black45 : Colors.black87,
                        fontStyle: noHpText == 'Nomor HP belum tersedia' ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: const Text('Petunjuk Arah', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: _openGoogleMaps,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.darkGreen,
                              side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('Chat Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: controller.isLoading ? null : _hubungiApotek,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search & Medicine Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: const [
                  Text(
                    'Daftar Obat Tersedia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: controller.filterMedicines,
                  decoration: const InputDecoration(
                    hintText: 'Cari obat di apotek ini...',
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),

          // Grid of medicines
          controller.isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.darkGreen),
                    ),
                  ),
                )
              : controller.filteredMedicines.isEmpty
                  ? SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child: Center(
                          child: Column(
                            children: const [
                              Icon(Icons.medication_liquid_rounded, size: 64, color: Colors.black26),
                              SizedBox(height: 12),
                              Text(
                                'Obat tidak tersedia atau habis',
                                style: TextStyle(color: Colors.black45, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = controller.filteredMedicines[index];
                            return _buildMedicineCard(context, product);
                          },
                          childCount: controller.filteredMedicines.length,
                        ),
                      ),
                    ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineCard(BuildContext context, Map<String, dynamic> product) {
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  product['gambar'] ?? product['imageUrl'] ?? 'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.medication, size: 50),
                ),
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['nama_obat'] ?? product['name'] ?? 'Obat',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${product['harga'] ?? product['price'] ?? 0}',
                    style: const TextStyle(
                      color: Color(0xFF4299E1),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stok: ${product['jumlah_stok']}',
                    style: const TextStyle(
                      color: Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
