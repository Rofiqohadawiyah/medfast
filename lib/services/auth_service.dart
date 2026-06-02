import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {
  // Mendapatkan data user saat ini dari SharedPreferences (offline/local cache)
  Future<UserModel?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Mendapatkan token saat ini
  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Register user baru (Pelanggan)
  Future<UserModel?> registerWithEmailAndPassword(
      String name, String email, String password, String phone, String role) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'nama': name,
        'email': email,
        'password': password,
        'no_hp': phone,
        'role': role,
        'alamat': '', // Alamat dikosongkan saat registrasi awal
      });

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = responseBody['data'];
        return UserModel.fromJson(userData);
      } else {
        throw responseBody['message'] ?? "Terjadi kesalahan saat registrasi";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Register admin baru dengan kode apotek
  Future<UserModel?> registerAdmin(
      String name, String email, String password, String phone, String pharmacyId, String pharmacyName, {String? kodeApotek}) async {
    try {
      // Jika kodeApotek dikirim lewat parameter, gunakan itu. 
      // Jika tidak, asumsikan pharmacyId berisi kode apotek (karena dipass dari UI)
      final codeToUse = kodeApotek ?? pharmacyId;

      final response = await ApiClient.post('/auth/register', {
        'nama': name,
        'email': email,
        'password': password,
        'no_hp': phone,
        'role': 'admin',
        'kode_apotek': codeToUse,
        'alamat': '',
      });

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final userData = responseBody['data'];
        return UserModel.fromJson(userData);
      } else {
        throw responseBody['message'] ?? "Terjadi kesalahan saat registrasi admin";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Login user
  Future<UserModel?> loginWithEmailAndPassword(String email, String password) async {
    try {
      final response = await ApiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseBody['token'];
        final userData = responseBody['user'];

        // Simpan ke SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('user_data', jsonEncode(userData));

        return UserModel.fromJson(userData);
      } else {
        throw responseBody['message'] ?? "Email atau password salah";
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // Mendapatkan data user berdasarkan token JWT (mengambil dari API /profile)
  Future<UserModel?> getUserData(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');
      
      if (savedToken == null) return null;

      final response = await ApiClient.get('/profile', token: savedToken);
      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        
        // Update local cache
        await prefs.setString('user_data', response.body);
        
        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print("Error getting user data: ${e.toString()}");
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('user_data');
    } catch (e) {
      print("Error signing out: ${e.toString()}");
    }
  }
}
