import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_client.dart';

class AuthService {

  Future<UserModel?> get currentUser async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      return UserModel.fromJson(jsonDecode(userJson));
    }
    return null;
  }


  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }


  Future<UserModel?> registerWithEmailAndPassword(
      String name, String email, String password, String phone, String role) async {
    try {
      final response = await ApiClient.post('/auth/register', {
        'nama': name,
        'email': email,
        'password': password,
        'no_hp': phone,
        'role': role,
        'alamat': '',
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


  Future<UserModel?> registerAdmin(
      String name, String email, String password, String phone, String pharmacyId, String pharmacyName, {String? kodeApotek}) async {
    try {


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


  Future<UserModel?> getUserData(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('jwt_token');

      if (savedToken == null) return null;

      final response = await ApiClient.get('/profile', token: savedToken);
      if (response.statusCode == 200) {
        final rawData = jsonDecode(response.body);



        Map<String, dynamic> userData;
        if (rawData is Map<String, dynamic>) {
          Map<String, dynamic>? nested;
          for (final key in ['user', 'data', 'result']) {
            final v = rawData[key];
            if (v is Map<String, dynamic>) {
              nested = v;
              break;
            }
          }
          userData = nested ?? rawData;
        } else {
          return null;
        }


        await prefs.setString('user_data', jsonEncode(userData));

        return UserModel.fromJson(userData);
      }
      return null;
    } catch (e) {
      print("Error getting user data: ${e.toString()}");
      return null;
    }
  }


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
