import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import '../services/api_client.dart';
import 'chat_page.dart';
import 'apotek_detail_page.dart';

class ApotekPage extends StatefulWidget {
  const ApotekPage({super.key});

  @override
  State<ApotekPage> createState() => _ApotekPageState();
}

class _ApotekPageState extends State<ApotekPage> {
  final MapController _mapController = MapController();
  LatLng _userLocation = const LatLng(-8.1647, 113.7152); // Default Jember
  bool _locationLoaded = false;
  int _selectedApotekIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final addressStr = user?.alamat?.toString() ?? '';
      _calculateDistanceForApoteks(addressStr);
    });
  }

  Future<void> _calculateDistanceForApoteks(String addressStr) async {
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
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          if (mounted) {
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
              _locationLoaded = true;
            });
            _mapController.move(_userLocation, 14);
          }
          return;
        }
      }
    } catch (_) {}

    // 2. Geocode address string using Nominatim if GPS failed
    if (addressStr.isNotEmpty) {
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
              _mapController.move(_userLocation, 14);
            }
            return;
          }
        }
      } catch (_) {}
    }
  }


  void _openGoogleMaps(double lat, double lng, String name) async {
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($name)');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback ke browser
      final webUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
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
      
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);
      
      final now = DateTime.now();
      final nowHour = now.hour;
      final nowMin = now.minute;
      
      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;
      final nowMinutes = nowHour * 60 + nowMin;
      
      if (startMinutes <= endMinutes) {
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      } else {
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  Widget _buildStatusBadge(String jamOperasional) {
    final isOpen = _isApotekOpen(jamOperasional);
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

  void _hubungiApotek(Map<String, dynamic> apotek) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    final idApotek = apotek['id_apotek'];
    final idAdmin = apotek['id_admin'];
    final apotekName = apotek['nama_apotek'] ?? 'Apotek';

    if (idApotek == null || idAdmin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data apotek tidak lengkap untuk chat')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.darkGreen)),
    );

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post(
        '/chat/room',
        {
          'id_pelanggan': int.parse(user.uid),
          'id_admin': idAdmin,
          'id_apotek': idApotek,
        },
        token: token,
      );

      if (mounted) {
        Navigator.pop(context); // Pop loading
      }

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
                idAdmin: idAdmin,
              ),
            ),
          );
        }
      } else {
        throw Exception('Gagal membuat room chat');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Pop loading if showing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memulai chat: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: FutureBuilder<http.Response>(
        future: ApiClient.get('/apotek'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.darkGreen));
          }

          if (snapshot.hasError || snapshot.data == null || snapshot.data!.statusCode != 200) {
            return const Center(child: Text('Gagal memuat daftar apotek dari server lokal.'));
          }

          final List<dynamic> pharmacies = jsonDecode(snapshot.data!.body);

          // Buat daftar marker dari data API
          final markers = <Marker>[
            // Marker lokasi user
            if (_locationLoaded)
              Marker(
                point: _userLocation,
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

          return Column(
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
                        initialCenter: _userLocation,
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
                          double? distanceKm;
                          if (_locationLoaded) {
                            final distanceM = Geolocator.distanceBetween(
                              _userLocation.latitude,
                              _userLocation.longitude,
                              lat,
                              lng,
                            );
                            distanceKm = distanceM / 1000;
                          }

                          return GestureDetector(
                            onTap: () {
                              if (_selectedApotekIndex == index) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApotekDetailPage(apotek: data),
                                  ),
                                );
                              } else {
                                _mapController.move(LatLng(lat, lng), 16);
                                setState(() => _selectedApotekIndex = index);
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
                                color: _selectedApotekIndex == index
                                    ? AppColors.darkGreen.withOpacity(0.08)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: _selectedApotekIndex == index
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
                                            _buildStatusBadge(jamOperasional),
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
                                    onPressed: () => _openGoogleMaps(lat, lng, name),
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
          );
        },
      ),
    );
  }
}
