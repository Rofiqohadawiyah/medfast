import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'product_detail_page.dart';

class ApotekDetailPage extends StatefulWidget {
  final Map<String, dynamic> apotek;

  const ApotekDetailPage({super.key, required this.apotek});

  @override
  State<ApotekDetailPage> createState() => _ApotekDetailPageState();
}

class _ApotekDetailPageState extends State<ApotekDetailPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  double? _distanceKm;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _loadLocationAndMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationAndMedicines() async {
    await _calculateDistance();
    await _fetchMedicines();
  }

  Future<void> _calculateDistance() async {
    final lat = (widget.apotek['latitude'] as num?)?.toDouble();
    final lng = (widget.apotek['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final addressStr = user?.alamat?.toString() ?? '';

    // 1. Try GPS First
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
          _userLocation = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (_) {}

    // 2. Fallback: Geocode address string using Nominatim if GPS failed
    if (_userLocation == null && addressStr.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(addressStr)}&limit=1',
        );
        final searchRes = await http.get(searchUrl, headers: {'User-Agent': 'MedFastApp/1.0'});
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            final userLat = double.parse(list[0]['lat']);
            final userLon = double.parse(list[0]['lon']);
            _userLocation = LatLng(userLat, userLon);
          }
        }
      } catch (_) {}
    }

    if (_userLocation != null) {
      final distanceM = Geolocator.distanceBetween(
        _userLocation!.latitude,
        _userLocation!.longitude,
        lat,
        lng,
      );
      if (mounted) {
        setState(() {
          _distanceKm = distanceM / 1000.0;
        });
      }
    }
  }

  Future<void> _fetchMedicines() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final apotekId = widget.apotek['id_apotek'];
      if (apotekId == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Use the filtered endpoint: /stok-obat?id_apotek=X
      // This returns stock rows with embedded obat data
      final stockRes = await ApiClient.get('/stok-obat?id_apotek=$apotekId');
      List<dynamic> stockList = [];
      if (stockRes.statusCode == 200) {
        stockList = jsonDecode(stockRes.body);
      }

      // Map stock rows into medicine cards
      final List<Map<String, dynamic>> matchedMedicines = [];
      for (var stock in stockList) {
        final obat = stock['obat'];
        if (obat == null) continue;

        final mapped = Map<String, dynamic>.from(obat);
        mapped['jumlah_stok'] = stock['jumlah_stok'] ?? 0;
        // Ensure id_obat is available for navigation
        mapped['id_obat'] = obat['id_obat'] ?? stock['id_obat'];
        matchedMedicines.add(mapped);
      }

      if (mounted) {
        setState(() {
          _medicines = matchedMedicines;
          _filteredMedicines = matchedMedicines;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterMedicines(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredMedicines = _medicines.where((med) {
        final name = (med['nama_obat'] ?? med['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    });
  }

  bool _isApotekOpen(dynamic jamOperasional) {
    if (jamOperasional == null) return false;
    final String jamStr = jamOperasional.toString();
    if (jamStr.isEmpty || jamStr == '-') return false;
    try {
      final parts = jamStr.split('-');
      if (parts.length != 2) return false;
      
      final startStr = parts[0].trim().replaceAll('.', ':');
      final endStr = parts[1].trim().replaceAll('.', ':');
      
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      if (startParts.length < 2 || endParts.length < 2) return false;
      
      final now = TimeOfDay.now();
      final start = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
      final end = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
      
      final double nowDouble = now.hour + now.minute / 60.0;
      final double startDouble = start.hour + start.minute / 60.0;
      final double endDouble = end.hour + end.minute / 60.0;
      
      return nowDouble >= startDouble && nowDouble <= endDouble;
    } catch (_) {
      return false;
    }
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login terlebih dahulu')),
      );
      return;
    }

    final idApotek = widget.apotek['id_apotek'];
    final apotekName = widget.apotek['nama_apotek'] ?? 'Apotek';

    if (idApotek == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data apotek tidak lengkap')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    try {
      final authService = AuthService();
      final token = await authService.token;

      // Step 1: Find the admin id for this apotek
      // The apotek table doesn't have id_admin, so look it up from the profile endpoint
      // The apotek data from API includes id_admin if we select it correctly.
      // As fallback, try to get it from the apotek object, otherwise search users
      int? idAdmin = widget.apotek['id_admin'] != null
          ? (widget.apotek['id_admin'] as num).toInt()
          : null;

      if (idAdmin == null) {
        // Fetch all users and find admin for this apotek
        final usersRes = await ApiClient.get('/auth/users');
        if (usersRes.statusCode == 200) {
          final List<dynamic> users = jsonDecode(usersRes.body);
          final admin = users.firstWhere(
            (u) => u['role'] == 'admin' && u['id_apotek']?.toString() == idApotek.toString(),
            orElse: () => null,
          );
          if (admin != null) {
            idAdmin = (admin['id_user'] as num?)?.toInt();
          }
        }
      }

      if (idAdmin == null) {
        if (mounted) Navigator.pop(context);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Apotek ini belum memiliki admin chat aktif.')),
          );
        }
        return;
      }

      // Step 2: Create or get existing chat room
      final response = await ApiClient.post(
        '/chat/room',
        {
          'id_pelanggan': int.parse(user.uid),
          'id_admin': idAdmin,
          'id_apotek': idApotek,
        },
        token: token,
      );

      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        final chatId = room['id_chat'];

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                chatId: chatId,
                roomName: apotekName,
                idAdmin: idAdmin!,
              ),
            ),
          );
        }
      } else {
        throw Exception('Gagal membuat room chat');
      }
    } catch (e) {
      if (mounted) {
        try { Navigator.pop(context); } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai chat: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.apotek['nama_apotek'] ?? widget.apotek['name'] ?? 'Apotek';
    final address = widget.apotek['alamat'] ?? widget.apotek['alamat_apotek'] ?? widget.apotek['address'] ?? '-';
    final jamOperasional = widget.apotek['jam_operasional'] ?? '-';
    final isOpen = _isApotekOpen(jamOperasional);

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
                    color: Colors.white.withOpacity(0.15),
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
                      color: Colors.black.withOpacity(0.04),
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
                            color: isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
                        if (_distanceKm != null)
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
                                  '${_distanceKm!.toStringAsFixed(1)} km',
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
                            onPressed: _hubungiApotek,
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
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterMedicines,
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
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50.0),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.darkGreen),
                    ),
                  ),
                )
              : _filteredMedicines.isEmpty
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
                            final product = _filteredMedicines[index];
                            return _buildMedicineCard(context, product);
                          },
                          childCount: _filteredMedicines.length,
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
              color: Colors.black.withOpacity(0.04),
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
