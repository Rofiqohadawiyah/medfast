import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class DataPribadiController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<UserModel?> updateProfile(UserModel currentUser, String name, String phone) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put('/profile', {
        'nama': name,
        'no_hp': phone,
      }, token: token);

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

        // Update local SharedPreferences cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedUser.toJson()));

        _successMessage = 'Profil berhasil diperbarui';
        return updatedUser;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui profil';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }
}
