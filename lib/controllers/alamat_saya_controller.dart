import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AlamatSayaController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<UserModel?> updateAlamat(UserModel user, String newAddress) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put('/profile', {
        'nama': user.name,
        'no_hp': user.phone,
        'alamat': newAddress,
      }, token: token);

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final updatedData = responseBody['data'];
        final updatedUser = UserModel.fromJson(updatedData);


        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedData));

        _successMessage = newAddress.isEmpty ? 'Alamat berhasil dihapus!' : 'Alamat berhasil disimpan!';
        return updatedUser;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui alamat';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Gagal: ${e.toString()}';
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
