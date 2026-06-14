import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/pilih_alamat_controller.dart';
import '../utils/colors.dart';

class PilihAlamatPage extends StatelessWidget {
  const PilihAlamatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PilihAlamatController(),
      child: const _PilihAlamatUI(),
    );
  }
}

class _PilihAlamatUI extends StatefulWidget {
  const _PilihAlamatUI();

  @override
  State<_PilihAlamatUI> createState() => _PilihAlamatUIState();
}

class _PilihAlamatUIState extends State<_PilihAlamatUI> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PilihAlamatController>().goToCurrentLocation().then((_) {
        final ctrl = context.read<PilihAlamatController>();
        _mapController.move(ctrl.selectedPoint, 16);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PilihAlamatController>();

    if (controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!)),
        );
        controller.clearError();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, left: 8, right: 16, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
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
                    'Pilih Lokasi Pengiriman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (controller.isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
              ],
            ),
          ),


          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: controller.selectedPoint,
                    initialZoom: 15,
                    onTap: (tapPosition, point) => controller.onMapTap(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.medfast',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: controller.selectedPoint,
                          width: 50,
                          height: 60,
                          child: const Column(
                            children: [
                              Icon(Icons.location_on, color: Color(0xFFD32F2F), size: 44),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),


                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (query) async {
                        final point = await controller.searchAddress(query);
                        if (point != null) {
                          _mapController.move(point, 16);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama tempat / jalan...',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.darkGreen),
                        suffixIcon: controller.isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkGreen),
                                ),
                              )
                            : _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.black45),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (val) {
                        setState(() {});
                      },
                    ),
                  ),
                ),


                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: () async {
                       await controller.goToCurrentLocation();
                       _mapController.move(controller.selectedPoint, 16);
                    },
                    child: const Icon(Icons.my_location, color: AppColors.darkGreen),
                  ),
                ),


                Positioned(
                  top: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '👆 Ketuk peta / gunakan kolom pencarian',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),


          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Alamat Terpilih:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: AppColors.darkGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: controller.isLoadingAddress
                          ? const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Mengambil alamat...', style: TextStyle(color: Colors.black54)),
                              ],
                            )
                          : Text(
                              controller.selectedAddress,
                              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
                            ),
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
                    onPressed: controller.isLoadingAddress
                        ? null
                        : () {

                            Navigator.pop(context, {
                              'address': controller.selectedAddress,
                              'latitude': controller.selectedPoint.latitude,
                              'longitude': controller.selectedPoint.longitude,
                            });
                          },
                    child: const Text(
                      'Gunakan Alamat Ini',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
