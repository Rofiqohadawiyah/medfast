import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class PasswordController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _successMessage;
  String? get successMessage => _successMessage;

  Future<bool> changePassword(String oldPw, String newPw, String confPw) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    if (oldPw.isEmpty || newPw.isEmpty || confPw.isEmpty) {
      _errorMessage = 'Semua field wajib diisi';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (newPw != confPw) {
      _errorMessage = 'Konfirmasi password baru tidak sesuai';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (newPw.length < 6) {
      _errorMessage = 'Password baru minimal harus 6 karakter';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put(
        '/profile/change-password',
        {
          'old_password': oldPw,
          'new_password': newPw,
        },
        token: token,
      );

      if (response.statusCode == 200) {
        _successMessage = 'Password berhasil diubah';
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal mengubah password';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
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
