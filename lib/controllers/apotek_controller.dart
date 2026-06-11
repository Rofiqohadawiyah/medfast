import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ApotekController extends ChangeNotifier {
  LatLng userLocation = const LatLng(-8.1647, 113.7152); // Default Jember
  bool locationLoaded = false;
  int selectedApotekIndex = -1;
  List<dynamic> pharmacies = [];
  bool isLoading = true;
  String? errorMessage;

  // Chat room creation result
  int? createdChatId;
  String? createdChatName;
  int? createdChatAdminId;
  bool isChatLoading = false;

  /// Load pharmacies from API.
  Future<void> loadPharmacies() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get('/apotek');
      if (res.statusCode == 200) {
        pharmacies = jsonDecode(res.body);
      } else {
        errorMessage = 'Gagal memuat daftar apotek dari server.';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate user location from GPS or geocoding, then load pharmacies.
  Future<void> initData(String addressStr) async {
    await _resolveUserLocation(addressStr);
    await loadPharmacies();
  }

  /// Resolve user location via GPS first, then fallback to geocoding.
  Future<void> _resolveUserLocation(String addressStr) async {
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
          userLocation = LatLng(position.latitude, position.longitude);
          locationLoaded = true;
          notifyListeners();
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
            userLocation = LatLng(lat, lon);
            locationLoaded = true;
            notifyListeners();
            return;
          }
        }
      } catch (_) {}
    }
  }

  /// Open Google Maps navigation for a given coordinate.
  Future<void> openGoogleMaps(double lat, double lng, String name) async {
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

  /// Check if an apotek is currently open based on its operational hours string.
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

  /// Select an apotek by index.
  void selectApotek(int index) {
    selectedApotekIndex = index;
    notifyListeners();
  }

  /// Calculate distance from user location to a coordinate.
  double? calculateDistance(double lat, double lng) {
    if (!locationLoaded) return null;
    final distanceM = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      lat,
      lng,
    );
    return distanceM / 1000;
  }

  /// Create or get a chat room with an apotek, returns true on success.
  Future<bool> hubungiApotek(Map<String, dynamic> apotek, String userId) async {
    final idApotek = apotek['id_apotek'];
    final idAdmin = apotek['id_admin'];
    final apotekName = apotek['nama_apotek'] ?? 'Apotek';

    if (idApotek == null || idAdmin == null) {
      errorMessage = 'Data apotek tidak lengkap untuk chat';
      notifyListeners();
      return false;
    }

    isChatLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post(
        '/chat/room',
        {
          'id_pelanggan': int.parse(userId),
          'id_admin': idAdmin,
          'id_apotek': idApotek,
        },
        token: token,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        createdChatId = room['id_chat'];
        createdChatName = apotekName;
        createdChatAdminId = idAdmin;
        return true;
      } else {
        errorMessage = 'Gagal membuat room chat';
        return false;
      }
    } catch (e) {
      errorMessage = 'Gagal memulai chat: ${e.toString()}';
      return false;
    } finally {
      isChatLoading = false;
      notifyListeners();
    }
  }
}
