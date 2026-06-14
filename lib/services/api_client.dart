import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  static String get baseUrl {
    return 'https://medfastapi-production.up.railway.app/api';
  }


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
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    return await request.send();
  }
}
