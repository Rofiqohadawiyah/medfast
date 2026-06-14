import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class PilihAlamatController extends ChangeNotifier {
  LatLng _selectedPoint = const LatLng(-8.1647, 113.7152);
  LatLng get selectedPoint => _selectedPoint;

  String _selectedAddress = 'Ketuk peta untuk memilih lokasi...';
  String get selectedAddress => _selectedAddress;

  bool _isLoadingAddress = false;
  bool get isLoadingAddress => _isLoadingAddress;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void clearError() {
    _errorMessage = null;
  }

  Future<void> goToCurrentLocation() async {
    _isLoadingLocation = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLoadingLocation = false;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final point = LatLng(pos.latitude, pos.longitude);

      _selectedPoint = point;
      _isLoadingLocation = false;
      notifyListeners();

      await reverseGeocode(point);
    } catch (e) {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  Future<LatLng?> searchAddress(String query) async {
    if (query.trim().isEmpty) return null;

    _isSearching = true;
    notifyListeners();

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
          _selectedPoint = point;
          _selectedAddress = displayName;
          _isSearching = false;
          notifyListeners();
          return point;
        } else {
          _errorMessage = 'Lokasi tidak ditemukan';
        }
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      _isSearching = false;
      notifyListeners();
    }
    return null;
  }

  Future<void> reverseGeocode(LatLng point) async {
    _isLoadingAddress = true;
    _selectedAddress = 'Mengambil nama jalan...';
    notifyListeners();

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
        _selectedAddress = address;
      } else {
        _selectedAddress = 'Gagal mengambil alamat. Coba lagi.';
      }
    } catch (e) {
      _selectedAddress = 'Gagal mengambil alamat. Coba lagi.';
    } finally {
      _isLoadingAddress = false;
      notifyListeners();
    }
  }

  void onMapTap(LatLng point) {
    _selectedPoint = point;
    notifyListeners();
    reverseGeocode(point);
  }
}
