import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';

class LandingController extends ChangeNotifier {
  String searchQuery = '';
  String locationName = 'Mendeteksi lokasi...';
  bool locationLoading = true;

  Map<String, Map<String, dynamic>> productApotekMap = {};

  List<dynamic> allProducts = [];
  List<dynamic> filteredProducts = [];
  bool productsLoading = true;
  String? errorMessage;

  LandingController() {
    _initData();
  }

  Future<void> _initData() async {
    fetchLocation();
    await fetchProductsAndApotek();
  }

  Future<void> fetchLocation() async {
    locationLoading = true;
    notifyListeners();

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        locationName = 'Izin lokasi ditolak';
        locationLoading = false;
        notifyListeners();
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationName = 'GPS tidak aktif';
        locationLoading = false;
        notifyListeners();
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );


      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${pos.latitude}&lon=${pos.longitude}&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'Accept-Language': 'id', 'User-Agent': 'MedFastApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        final road =
            (addr['road'] ??
                    addr['suburb'] ??
                    addr['village'] ??
                    addr['neighbourhood'] ??
                    '')
                as String;
        final city =
            (addr['city'] ??
                    addr['town'] ??
                    addr['county'] ??
                    addr['municipality'] ??
                    '')
                as String;

        final parts = [road, city].where((e) => e.isNotEmpty).toList();
        locationName = parts.isNotEmpty
            ? parts.join(', ')
            : 'Lokasi tidak diketahui';
      } else {
        locationName = 'Gagal deteksi lokasi';
      }
    } catch (e) {
      locationName = 'Gagal deteksi lokasi';
    }

    locationLoading = false;
    notifyListeners();
  }

  Future<void> fetchProductsAndApotek() async {
    productsLoading = true;
    errorMessage = null;
    notifyListeners();

    try {

      final responses = await Future.wait([
        ApiClient.get('/apotek'),
        ApiClient.get('/stok-obat'),
        ApiClient.get('/obat'),
      ]);

      final apotekRes = responses[0];
      final stockRes = responses[1];
      final obatRes = responses[2];


      if (apotekRes.statusCode == 200 && stockRes.statusCode == 200) {
        final List<dynamic> apoteks = jsonDecode(apotekRes.body);
        final List<dynamic> stocks = jsonDecode(stockRes.body);

        final newMap = <String, Map<String, dynamic>>{};
        for (var stock in stocks) {
          final idObat = stock['id_obat']?.toString();
          final idApotek = stock['id_apotek']?.toString();
          final stok = (stock['jumlah_stok'] ?? 0) as num;

          if (idObat != null && idApotek != null && stok > 0) {
            if (!newMap.containsKey(idObat)) {
              final matchApotek = apoteks.firstWhere(
                (a) => a['id_apotek']?.toString() == idApotek,
                orElse: () => null,
              );
              if (matchApotek != null) {
                newMap[idObat] = matchApotek;
              }
            }
          }
        }
        productApotekMap = newMap;
      }


      if (obatRes.statusCode == 200) {
        allProducts = jsonDecode(obatRes.body);
      } else {
        errorMessage = 'Gagal memuat produk dari server';
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan koneksi';
    }

    _filterProducts();
    productsLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    searchQuery = query.toLowerCase();
    _filterProducts();
    notifyListeners();
  }

  void _filterProducts() {
    filteredProducts = allProducts.where((p) {
      final idObat = (p['id_obat'] ?? p['id'] ?? '').toString();

      if (!productApotekMap.containsKey(idObat)) return false;

      var name = (p['nama_obat'] ?? p['name'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery);
    }).toList();
  }
}
