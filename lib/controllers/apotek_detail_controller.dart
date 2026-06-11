import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ApotekDetailController extends ChangeNotifier {
  bool isLoading = true;
  List<Map<String, dynamic>> medicines = [];
  List<Map<String, dynamic>> filteredMedicines = [];
  String searchQuery = '';
  double? distanceKm;
  String? errorMessage;

  Future<void> loadLocationAndMedicines(
    Map<String, dynamic> apotek,
    String addressStr,
  ) async {
    await calculateDistance(apotek, addressStr);
    await fetchMedicines(apotek);
  }

  Future<void> calculateDistance(
    Map<String, dynamic> apotek,
    String addressStr,
  ) async {
    final lat = (apotek['latitude'] as num?)?.toDouble();
    final lng = (apotek['longitude'] as num?)?.toDouble();
    if (lat == null || lng == null) return;

    double? userLat;
    double? userLng;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          userLat = position.latitude;
          userLng = position.longitude;
        }
      }
    } catch (_) {}

    if ((userLat == null || userLng == null) && addressStr.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=\${Uri.encodeComponent(addressStr)}&limit=1',
        );
        final searchRes = await http.get(
          searchUrl,
          headers: {'User-Agent': 'MedFastApp/1.0'},
        );
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            userLat = double.parse(list[0]['lat']);
            userLng = double.parse(list[0]['lon']);
          }
        }
      } catch (_) {}
    }

    if (userLat != null && userLng != null) {
      final distanceM = Geolocator.distanceBetween(userLat, userLng, lat, lng);
      distanceKm = distanceM / 1000.0;
      notifyListeners();
    }
  }

  Future<void> fetchMedicines(Map<String, dynamic> apotek) async {
    isLoading = true;
    notifyListeners();

    try {
      final apotekId = apotek['id_apotek'];
      if (apotekId == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      final stockRes = await ApiClient.get('/stok-obat?id_apotek=\$apotekId');
      List<dynamic> stockList = [];
      if (stockRes.statusCode == 200) {
        stockList = jsonDecode(stockRes.body);
      }

      final List<Map<String, dynamic>> matchedMedicines = [];
      for (var stock in stockList) {
        final obat = stock['obat'];
        if (obat == null) continue;

        final mapped = Map<String, dynamic>.from(obat);
        mapped['jumlah_stok'] = stock['jumlah_stok'] ?? 0;
        mapped['id_obat'] = obat['id_obat'] ?? stock['id_obat'];
        matchedMedicines.add(mapped);
      }

      medicines = matchedMedicines;
      filteredMedicines = matchedMedicines;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void filterMedicines(String query) {
    searchQuery = query.toLowerCase();
    filteredMedicines = medicines.where((med) {
      final name = (med['nama_obat'] ?? med['name'] ?? '')
          .toString()
          .toLowerCase();
      return name.contains(searchQuery);
    }).toList();
    notifyListeners();
  }

  Future<int?> hubungiApotek(Map<String, dynamic> apotek, String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final idApotek = apotek['id_apotek'];
      if (idApotek == null) {
        errorMessage = 'Data apotek tidak lengkap';
        return null;
      }

      int? idAdmin = apotek['id_admin'] != null
          ? (apotek['id_admin'] as num).toInt()
          : null;

      if (idAdmin == null) {
        final usersRes = await ApiClient.get('/auth/users');
        if (usersRes.statusCode == 200) {
          final List<dynamic> users = jsonDecode(usersRes.body);
          final admin = users.firstWhere(
            (u) =>
                u['role'] == 'admin' &&
                u['id_apotek']?.toString() == idApotek.toString(),
            orElse: () => null,
          );
          if (admin != null) {
            idAdmin = (admin['id_user'] as num?)?.toInt();
          }
        }
      }

      if (idAdmin == null) {
        errorMessage = 'Apotek ini belum memiliki admin chat aktif.';
        return null;
      }

      final response = await ApiClient.post('/chat/room', {
        'id_pelanggan': int.parse(userId),
        'id_admin': idAdmin,
        'id_apotek': idApotek,
      }, token: token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        return room['id_chat']; // Return chatId and idAdmin in a map or just return chatid
      } else {
        errorMessage = 'Gagal membuat room chat';
        return null;
      }
    } catch (e) {
      errorMessage = 'Gagal memulai chat: \${e.toString()}';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool isApotekOpen(dynamic jamOperasional) {
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
      final start = TimeOfDay(
        hour: int.parse(startParts[0]),
        minute: int.parse(startParts[1]),
      );
      final end = TimeOfDay(
        hour: int.parse(endParts[0]),
        minute: int.parse(endParts[1]),
      );

      final double nowDouble = now.hour + now.minute / 60.0;
      final double startDouble = start.hour + start.minute / 60.0;
      final double endDouble = end.hour + end.minute / 60.0;

      return nowDouble >= startDouble && nowDouble <= endDouble;
    } catch (_) {
      return false;
    }
  }
}
