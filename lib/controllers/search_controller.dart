import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../services/api_client.dart';

class SearchController extends ChangeNotifier {
  List<dynamic> allMedicines = [];
  List<dynamic> filteredMedicines = [];
  bool isLoading = false;

  LatLng userLocation = const LatLng(-8.1647, 113.7152);
  bool locationLoaded = false;
  String searchQuery = '';

  Future<void> initData(String addressStr) async {
    isLoading = true;
    notifyListeners();


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
          userLocation = LatLng(position.latitude, position.longitude);
          locationLoaded = true;
        }
      }
    } catch (_) {}

    if (!locationLoaded && addressStr.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(addressStr)}&limit=1',
        );
        final searchRes = await http.get(
          searchUrl,
          headers: {'User-Agent': 'MedFastApp/1.0'},
        );
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            final lat = double.parse(list[0]['lat']);
            final lon = double.parse(list[0]['lon']);
            userLocation = LatLng(lat, lon);
            locationLoaded = true;
          }
        }
      } catch (_) {}
    }


    try {
      final responses = await Future.wait([
        ApiClient.get('/apotek'),
        ApiClient.get('/stok-obat'),
        ApiClient.get('/obat'),
      ]);

      List<dynamic> apoteks = [];
      List<dynamic> stockList = [];

      if (responses[0].statusCode == 200) {
        apoteks = jsonDecode(responses[0].body);
      }
      if (responses[1].statusCode == 200) {
        stockList = jsonDecode(responses[1].body);
      }

      if (responses[2].statusCode == 200) {
        final List<dynamic> obatDataRaw = jsonDecode(responses[2].body);

        final List<dynamic> obatData = obatDataRaw.where((item) {
          final idObat = item['id_obat'] ?? item['id'];
          return stockList.any(
            (stock) =>
                stock['id_obat']?.toString() == idObat?.toString() &&
                (stock['jumlah_stok'] ?? 0) > 0,
          );
        }).toList();

        for (var item in obatData) {
          final idObat = item['id_obat'] ?? item['id'];
          final matches = stockList.where(
            (stock) =>
                stock['id_obat']?.toString() == idObat?.toString() &&
                (stock['jumlah_stok'] ?? 0) > 0,
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
                  userLocation.latitude,
                  userLocation.longitude,
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

        allMedicines = obatData;
        _filterAndSortData();
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  void onSearchChanged(String query) {
    searchQuery = query;
    _filterAndSortData();
    notifyListeners();
  }

  void _filterAndSortData() {
    final query = searchQuery.toLowerCase();

    List<dynamic> filtered;
    if (query.isEmpty) {
      filtered = List.from(allMedicines);
    } else {
      filtered = allMedicines.where((item) {
        final name = (item['nama_obat'] ?? item['name'] ?? '')
            .toString()
            .toLowerCase();
        final desc = (item['deskripsi'] ?? '').toString().toLowerCase();
        return name.contains(query) || desc.contains(query);
      }).toList();
    }

    filtered.sort((a, b) {
      final distA = a['closest_distance'] as double?;
      final distB = b['closest_distance'] as double?;

      if (distA == null && distB == null) return 0;
      if (distA == null) return 1;
      if (distB == null) return -1;
      return distA.compareTo(distB);
    });

    filteredMedicines = filtered;
  }
}
