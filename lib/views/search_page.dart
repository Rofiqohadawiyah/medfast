import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../utils/colors.dart';
import 'product_detail_page.dart';

class SearchPage extends StatefulWidget {
  final int selectedTab;

  const SearchPage({
    super.key,
    this.selectedTab = 0,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<dynamic> _allMedicines = [];
  List<dynamic> _filteredMedicines = [];
  bool _isLoading = false;

  LatLng _userLocation = const LatLng(-8.1647, 113.7152); // Default Jember
  bool _locationLoaded = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMedicinesAndDistances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicinesAndDistances() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // 1. Fetch user location (Prioritize GPS first, fallback to Nominatim geocoding)
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final addressStr = user?.alamat?.toString() ?? '';

    // A. Try GPS First
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
              _locationLoaded = true;
            });
          }
        }
      }
    } catch (_) {}

    // B. Geocode address string using Nominatim if GPS failed
    if (!_locationLoaded && addressStr.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(addressStr)}&limit=1',
        );
        final searchRes = await http.get(searchUrl, headers: {'User-Agent': 'MedFastApp/1.0'});
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            final lat = double.parse(list[0]['lat']);
            final lon = double.parse(list[0]['lon']);
            if (mounted) {
              setState(() {
                _userLocation = LatLng(lat, lon);
                _locationLoaded = true;
              });
            }
          }
        }
      } catch (_) {}
    }

    // 2. Fetch Apoteks info (to get coordinates)
    List<dynamic> apoteks = [];
    try {
      final response = await ApiClient.get('/apotek');
      if (response.statusCode == 200) {
        apoteks = jsonDecode(response.body);
      }
    } catch (_) {}

    // 3. Fetch Stock mappings (to connect medicines to apoteks)
    List<dynamic> stockList = [];
    try {
      final response = await ApiClient.get('/stok-obat');
      if (response.statusCode == 200) {
        stockList = jsonDecode(response.body);
      }
    } catch (_) {}

    // 4. Fetch all Medicines and calculate closest distance for each
    try {
      final response = await ApiClient.get('/obat');
      if (response.statusCode == 200) {
        final List<dynamic> obatData = jsonDecode(response.body);

        for (var item in obatData) {
          final idObat = item['id_obat'] ?? item['id'];
          // Filter stock list for this medicine where stock is available (> 0)
          final matches = stockList.where(
            (stock) => stock['id_obat']?.toString() == idObat?.toString() && (stock['jumlah_stok'] ?? 0) > 0,
          );

          double? minDistance;
          String apotekName = 'Apotek Terdekat';

          for (var match in matches) {
            final apotekId = match['id_apotek'];
            final apotek = apoteks.firstWhere(
              (a) => a['id_apotek']?.toString() == apotekId?.toString(),
              orElse: () => null,
            );

            if (apotek != null) {
              final lat = (apotek['latitude'] as num?)?.toDouble();
              final lng = (apotek['longitude'] as num?)?.toDouble();
              
              if (lat != null && lng != null) {
                final distanceM = Geolocator.distanceBetween(
                  _userLocation.latitude,
                  _userLocation.longitude,
                  lat,
                  lng,
                );
                final distanceKm = distanceM / 1000.0;
                
                if (minDistance == null || distanceKm < minDistance) {
                  minDistance = distanceKm;
                  apotekName = apotek['nama_apotek'] ?? 'Apotek Terdekat';
                }
              }
            }
          }

          item['closest_distance'] = minDistance;
          item['closest_apotek_name'] = apotekName;
        }

        if (mounted) {
          setState(() {
            _allMedicines = obatData;
            _filterAndSortData();
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _filterAndSortData();
    });
  }

  void _filterAndSortData() {
    final query = _searchQuery.toLowerCase();

    // A. Filter data based on query
    List<dynamic> filtered;
    if (query.isEmpty) {
      filtered = List.from(_allMedicines);
    } else {
      filtered = _allMedicines.where((item) {
        final name = (item['nama_obat'] ?? item['name'] ?? '').toString().toLowerCase();
        final desc = (item['deskripsi'] ?? '').toString().toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    }

    // B. Sort by closest distance (closest first, items with no distance/out of stock go last)
    filtered.sort((a, b) {
      final distA = a['closest_distance'] as double?;
      final distB = b['closest_distance'] as double?;
      
      if (distA == null && distB == null) return 0;
      if (distA == null) return 1; // Put nulls at the end
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    setState(() {
      _filteredMedicines = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  _searchQuery.isNotEmpty ? 'Hasil Pencarian Obat' : 'Rekomendasi Obat Terdekat',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(color: AppColors.darkGreen),
                        ),
                      )
                    : _filteredMedicines.isEmpty
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
                            itemCount: _filteredMedicines.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 0.62,
                            ),
                            itemBuilder: (context, index) {
                              final item = _filteredMedicines[index];
                              final name = item['nama_obat'] ?? item['name'] ?? 'Nama Obat';
                              final rawPrice = item['harga'] ?? item['price'] ?? 0;
                              final price = 'Rp ${rawPrice.toString()}';
                              final image = item['gambar'] ?? item['imageUrl'] ?? '';
                              
                              final distVal = item['closest_distance'] as double?;
                              final apotekName = item['closest_apotek_name'] ?? 'Apotek Terdekat';
                              
                              // Location text display with distance information
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

  Widget _header(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final userAlamat = user?.alamat;
    final String addressText = (userAlamat != null && userAlamat.toString().isNotEmpty) ? userAlamat.toString() : 'Lokasi Anda';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFCFEAFF),
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
                    onChanged: _onSearchChanged,
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
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      _onSearchChanged('');
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