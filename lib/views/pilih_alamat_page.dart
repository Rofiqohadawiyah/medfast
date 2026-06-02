import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../utils/colors.dart';

class PilihAlamatPage extends StatefulWidget {
  const PilihAlamatPage({super.key});

  @override
  State<PilihAlamatPage> createState() => _PilihAlamatPageState();
}

class _PilihAlamatPageState extends State<PilihAlamatPage> {
  final MapController _mapController = MapController();
  LatLng _selectedPoint = const LatLng(-8.1647, 113.7152); // Default Jember
  String _selectedAddress = 'Ketuk peta untuk memilih lokasi...';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _goToCurrentLocation();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(pos.latitude, pos.longitude);

      if (mounted) {
        setState(() {
          _selectedPoint = point;
          _isLoadingLocation = false;
        });
        _mapController.move(point, 16);
        _reverseGeocode(point);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'Accept-Language': 'id',
        'User-Agent': 'MedFastApp/1.0',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final first = data[0];
          final lat = double.parse(first['lat']);
          final lon = double.parse(first['lon']);
          final displayName = first['display_name'] ?? 'Lokasi terpilih';
          
          final point = LatLng(lat, lon);
          if (mounted) {
            setState(() {
              _selectedPoint = point;
              _selectedAddress = displayName;
              _isSearching = false;
            });
            _mapController.move(point, 16);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Lokasi tidak ditemukan')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = 'Mengambil nama jalan...';
    });
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${point.latitude}&lon=${point.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(url, headers: {
        'Accept-Language': 'id',
        'User-Agent': 'MedFastApp/1.0',
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'] ?? 'Alamat tidak ditemukan';
        if (mounted) {
          setState(() {
            _selectedAddress = address;
            _isLoadingAddress = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Gagal mengambil alamat. Coba lagi.';
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
    _reverseGeocode(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
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
                if (_isLoadingLocation)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Peta (bisa diklik & dicari lokasinya)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: 15,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.medfast',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _selectedPoint,
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
                
                // Search Bar floating diatas peta
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
                      onSubmitted: _searchAddress,
                      decoration: InputDecoration(
                        hintText: 'Cari nama tempat / jalan...',
                        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: AppColors.darkGreen),
                        suffixIcon: _isSearching
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

                // Tombol lokasi saya
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    backgroundColor: Colors.white,
                    onPressed: _goToCurrentLocation,
                    child: const Icon(Icons.my_location, color: AppColors.darkGreen),
                  ),
                ),
                
                // Hint text
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

          // Panel alamat terpilih + tombol simpan
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
                      child: _isLoadingAddress
                          ? const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                SizedBox(width: 8),
                                Text('Mengambil alamat...', style: TextStyle(color: Colors.black54)),
                              ],
                            )
                          : Text(
                              _selectedAddress,
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
                    onPressed: _isLoadingAddress
                        ? null
                        : () {
                            // Kembalikan alamat ke halaman sebelumnya
                            Navigator.pop(context, {
                              'address': _selectedAddress,
                              'latitude': _selectedPoint.latitude,
                              'longitude': _selectedPoint.longitude,
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
