import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/apotek_controller.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'apotek_detail_page.dart';

class ApotekPage extends StatelessWidget {
  const ApotekPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ApotekController(),
      child: const _ApotekPageUI(),
    );
  }
}

class _ApotekPageUI extends StatefulWidget {
  const _ApotekPageUI();

  @override
  State<_ApotekPageUI> createState() => _ApotekPageUIState();
}

class _ApotekPageUIState extends State<_ApotekPageUI> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final addressStr = user?.alamat?.toString() ?? '';
      context.read<ApotekController>().initData(addressStr);
    });
  }

  void _hubungiApotek(Map<String, dynamic> apotek) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final controller = context.read<ApotekController>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    final success = await controller.hubungiApotek(apotek, user.uid);

    if (mounted) {
      Navigator.pop(context); // Pop loading
    }

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: controller.createdChatId!,
            roomName: controller.createdChatName!,
            idAdmin: controller.createdChatAdminId!,
          ),
        ),
      );
    } else if (controller.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildStatusBadge(ApotekController controller, String jamOperasional) {
    final isOpen = controller.isApotekOpen(jamOperasional);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen ? const Color(0xFFE8F5E9) : const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOpen ? const Color(0xFF81C784) : const Color(0xFFBDBDBD),
          width: 0.5,
        ),
      ),
      child: Text(
        isOpen ? 'Buka' : 'Tutup',
        style: TextStyle(
          color: isOpen ? const Color(0xFF2E7D32) : const Color(0xFF616161),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ApotekController>();

    if (controller.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.lightGreen,
        body: Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
      );
    }

    if (controller.errorMessage != null && controller.pharmacies.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.lightGreen,
        body: Center(child: Text(controller.errorMessage!)),
      );
    }

    final pharmacies = controller.pharmacies;

    // Buat daftar marker dari data API
    final markers = <Marker>[
      // Marker lokasi user
      if (controller.locationLoaded)
        Marker(
          point: controller.userLocation,
          width: 50,
          height: 50,
          child: const Icon(
            Icons.my_location,
            color: Colors.blue,
            size: 36,
          ),
        ),
      // Marker apotek dari API
      ...pharmacies.map((item) {
        final data = item as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble() ?? 0;
        final lng = (data['longitude'] as num?)?.toDouble() ?? 0;
        return Marker(
          point: LatLng(lat, lng),
          width: 50,
          height: 50,
          child: GestureDetector(
            onTap: () {
              _mapController.move(LatLng(lat, lng), 16);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ApotekDetailPage(apotek: data),
                ),
              );
            },
            child: const Icon(
              Icons.location_on,
              color: Color(0xFFD32F2F),
              size: 42,
            ),
          ),
        );
      }),
    ];

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, left: 24, right: 24, bottom: 30),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(50),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apotek Terdekat',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${pharmacies.length} apotek ditemukan',
                  style: const TextStyle(fontSize: 15, color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // PETA
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 250,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: controller.userLocation,
                    initialZoom: 13,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.medfast',
                    ),
                    MarkerLayer(markers: markers),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Judul List
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Daftar Apotek',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // LIST APOTEK
          Expanded(
            child: pharmacies.isEmpty
                ? const Center(child: Text('Belum ada apotek tersedia.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: pharmacies.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final data = pharmacies[index] as Map<String, dynamic>;
                      final lat = (data['latitude'] as num?)?.toDouble() ?? 0;
                      final lng = (data['longitude'] as num?)?.toDouble() ?? 0;
                      final name = data['nama_apotek'] ?? data['name'] ?? 'Apotek';
                      final address = data['alamat'] ?? data['alamat_apotek'] ?? data['address'] ?? '-';
                      final jamOperasional = data['jam_operasional'] ?? '-';

                      // Hitung jarak dari user
                      final distanceKm = controller.calculateDistance(lat, lng);

                      return GestureDetector(
                        onTap: () {
                          if (controller.selectedApotekIndex == index) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApotekDetailPage(apotek: data),
                              ),
                            );
                          } else {
                            _mapController.move(LatLng(lat, lng), 16);
                            controller.selectApotek(index);
                          }
                        },
                        onDoubleTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ApotekDetailPage(apotek: data),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: controller.selectedApotekIndex == index
                                ? AppColors.darkGreen.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: controller.selectedApotekIndex == index
                                ? Border.all(color: AppColors.darkGreen, width: 1.5)
                                : null,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.lightGreen,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.local_pharmacy, color: AppColors.darkGreen, size: 28),
                              ),
                              const SizedBox(width: 14),
                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildStatusBadge(controller, jamOperasional),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.black45),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                            maxLines: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.access_time, size: 14, color: Colors.black45),
                                            const SizedBox(width: 4),
                                            Text(
                                              jamOperasional,
                                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                        if (distanceKm != null)
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.directions_walk, size: 14, color: AppColors.darkGreen),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${distanceKm.toStringAsFixed(1)} km',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppColors.darkGreen,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Tombol Chat
                              IconButton(
                                onPressed: () => _hubungiApotek(data),
                                icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkGreen),
                                tooltip: 'Chat Apotek',
                              ),
                              // Tombol Navigasi
                              IconButton(
                                onPressed: () => controller.openGoogleMaps(lat, lng, name),
                                icon: const Icon(Icons.navigation, color: AppColors.darkGreen),
                                tooltip: 'Navigasi',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
