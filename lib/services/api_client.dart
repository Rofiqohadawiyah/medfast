import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  static String get baseUrl {
    // URL Server Production (Railway) yang sudah online
    return 'https://medfastapi-production.up.railway.app/api';

    // URL Server Lokal (untuk development)
    /*
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    // Menggunakan IP lokal laptop untuk HP fisik (atau 10.0.2.2 untuk emulator)
    return 'http://192.168.18.129:3000/api';
    */
  }

  // Helper untuk POST request
  static Future<http.Response> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // Helper untuk PUT request
  static Future<http.Response> put(String endpoint, Map<String, dynamic> body, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  // Helper untuk GET request
  static Future<http.Response> get(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.get(
      url,
      headers: headers,
    );
  }

  // Helper untuk DELETE request
  static Future<http.Response> delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return await http.delete(
      url,
      headers: headers,
    );
  }

  // Helper untuk request multipart (POST / PUT dengan upload gambar)
  static Future<http.StreamedResponse> multipart({
    required String method,
    required String endpoint,
    required Map<String, String> fields,
    List<int>? imageBytes,
    String? filename,
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest(method, url);
    
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields.addAll(fields);
    
    if (imageBytes != null && filename != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'gambar',
        imageBytes,
        filename: filename,
      ));
    }
    
    return await request.send();
  }
}
