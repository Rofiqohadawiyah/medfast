import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AdminProfilController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? apotekData;
  String? errorMessage;
  String? successMessage;


  Future<void> fetchApotekDetails(String? pharmacyId) async {
    if (pharmacyId == null) return;

    try {
      final res = await ApiClient.get('/apotek');
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final match = list.firstWhere(
          (a) => a['id_apotek']?.toString() == pharmacyId,
          orElse: () => null,
        );
        if (match != null) {
          apotekData = match;
          notifyListeners();
        }
      }
    } catch (_) {}
  }



  Future<UserModel?> updateProfile({
    required UserModel currentUser,
    required String name,
    required String phone,
  }) async {
    isLoading = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put(
        '/profile',
        {
          'nama': name,
          'no_hp': phone,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        final updatedUser = UserModel(
          uid: currentUser.uid,
          name: name,
          email: currentUser.email,
          role: currentUser.role,
          phone: phone,
          pharmacyId: currentUser.pharmacyId,
          pharmacyName: currentUser.pharmacyName,
          alamat: currentUser.alamat,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

        successMessage = 'Profil admin berhasil diperbarui';
        return updatedUser;
      } else {
        errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui profil';
        return null;
      }
    } catch (e) {
      errorMessage = 'Gagal: $e';
      return null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }


  String getApotekName() => apotekData?['nama_apotek'] ?? '-';
  String getApotekAddress() => apotekData?['alamat'] ?? '-';
  String getApotekLat() => (apotekData?['latitude'] ?? apotekData?['lat'] ?? '-').toString();
  String getApotekLng() => (apotekData?['longitude'] ?? apotekData?['lng'] ?? '-').toString();
  String getApotekJam() => apotekData?['jam_operasional'] ?? apotekData?['jam_kerja'] ?? '-';
}
