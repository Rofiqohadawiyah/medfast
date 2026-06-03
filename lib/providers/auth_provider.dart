import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserModel? _userModel;
  bool _isLoading = false;
  String _errorMessage = '';

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<bool> checkLoginStatus() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      UserModel? cachedUser = await _authService.currentUser;
      if (cachedUser != null) {
        _userModel = cachedUser;
        _isLoading = false;
        notifyListeners();
        // Coba perbarui data profil terbaru dari server secara background
        _authService.getUserData(cachedUser.uid).then((updatedUser) {
          if (updatedUser != null) {
            _userModel = updatedUser;
            notifyListeners();
          }
        });
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> initializeUser(String uid) async {
    _isLoading = true;
    notifyListeners();
    try {
      _userModel = await _authService.getUserData(uid);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? user = await _authService.loginWithEmailAndPassword(email, password);
      if (user != null) {
        _userModel = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Login gagal. Periksa kembali akun anda.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String role) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? user = await _authService.registerWithEmailAndPassword(name, email, password, phone, role);
      if (user != null) {
        _userModel = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Gagal menyimpan data user.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerAdmin(String name, String email, String password, String phone, String pharmacyId, String pharmacyName, {String? kodeApotek}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      UserModel? user = await _authService.registerAdmin(name, email, password, phone, pharmacyId, pharmacyName, kodeApotek: kodeApotek);
      if (user != null) {
        _userModel = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Gagal menyimpan data admin.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void updateUserFromModel(UserModel user) {
    _userModel = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.signOut();
    _userModel = null;
    notifyListeners();
  }
}
