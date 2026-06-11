import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../services/api_client.dart';
import '../services/auth_service.dart';

class AdminProdukController extends ChangeNotifier {
  List<dynamic> products = [];
  List<dynamic> filtered = [];
  bool loading = true;
  String searchQuery = '';
  String? errorMessage;

  Future<void> loadProducts(String? apotekId) async {
    loading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      if (token == null) {
        errorMessage = 'Token tidak ditemukan, silakan login ulang.';
        loading = false;
        notifyListeners();
        return;
      }

      final res = await ApiClient.get('/obat', token: token);
      if (res.statusCode != 200) {
        errorMessage = 'Gagal memuat produk: ${_tryParseError(res.body)}';
        loading = false;
        notifyListeners();
        return;
      }

      final rawList = jsonDecode(res.body) as List<dynamic>;

      Map<dynamic, Map<String, dynamic>> stokMap = {};
      if (apotekId != null) {
        try {
          final stokRes = await ApiClient.get(
            '/stok-obat?id_apotek=$apotekId',
            token: token,
          );
          if (stokRes.statusCode == 200) {
            final stokList = jsonDecode(stokRes.body) as List<dynamic>;
            for (final item in stokList) {
              final idObat = item['id_obat'];
              if (idObat != null) {
                stokMap[idObat] = item as Map<String, dynamic>;
              }
            }
          }
        } catch (_) {}
      }

      final list = rawList
          .where((item) => stokMap.containsKey(item['id_obat']))
          .map((item) {
            final idObat = item['id_obat'];
            final stokItem = stokMap[idObat];
            final int stockQty =
                ((stokItem?['jumlah_stok'] ?? stokItem?['stok'] ?? 0) as num)
                    .toInt();
            return <String, dynamic>{
              'id_obat': idObat,
              'id_stok': stokItem?['id_stok'],
              'nama_obat': item['nama_obat'] ?? '',
              'harga': item['harga'] ?? 0,
              'jumlah_stok': stockQty,
              'kategori': item['kategori'] ?? '',
              'deskripsi': item['deskripsi'] ?? '',
              'gambar': item['gambar'] ?? '',
            };
          })
          .toList();

      products = list.where((e) => (e['jumlah_stok'] as int) > 0).toList();
      _applyFilter();
      loading = false;
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error memuat produk: $e';
      loading = false;
      notifyListeners();
    }
  }

  String _tryParseError(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded['message'] ?? body;
    } catch (_) {
      return body;
    }
  }

  void onSearchChanged(String query) {
    searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    filtered = products.where((p) {
      final name = (p['nama_obat'] ?? p['name'] ?? '').toString().toLowerCase();
      final category = (p['kategori'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery) || category.contains(searchQuery);
    }).toList();
  }

  Future<bool> hapusProduk(Map<String, dynamic> data) async {
    final idStok = data['id_stok']?.toString();

    try {
      final authService = AuthService();
      final token = await authService.token;

      if (idStok != null && idStok.isNotEmpty) {
        final res = await ApiClient.put('/stok-obat/$idStok', {
          'jumlah_stok': 0,
        }, token: token);

        if (res.statusCode == 200 || res.statusCode == 201) {
          return true;
        } else {
          errorMessage =
              'Gagal menghapus [${res.statusCode}]: ${_tryParseError(res.body)}';
          notifyListeners();
          return false;
        }
      } else {
        errorMessage = 'Tidak bisa menghapus: data stok tidak ditemukan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = 'Gagal menghapus: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> simpanProduk({
    required bool isEdit,
    required String docId,
    required Map<String, String> fields,
    required Uint8List? imageBytes,
    required String stockStr,
    required String? pharmacyId,
  }) async {
    try {
      final authService = AuthService();
      final token = await authService.token;
      if (token == null)
        throw Exception('Token tidak ditemukan, silakan login ulang.');

      final streamed = await ApiClient.multipart(
        method: isEdit ? 'PUT' : 'POST',
        endpoint: isEdit ? '/obat/$docId' : '/obat',
        fields: fields,
        imageBytes: imageBytes,
        filename: imageBytes != null
            ? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : null,
        token: token,
      );

      final res = await http.Response.fromStream(streamed);

      if (res.statusCode == 200 || res.statusCode == 201) {
        Map<String, dynamic> resData = {};
        try {
          resData = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}

        String newObatId = '';
        for (final key in ['data', 'obat', 'result', 'item']) {
          final block = resData[key];
          if (block != null && block is Map) {
            final id = (block['id_obat'] ?? block['id'] ?? '').toString();
            if (id.isNotEmpty && id != 'null') {
              newObatId = id;
              break;
            }
          }
        }
        if (newObatId.isEmpty) {
          newObatId = (resData['id_obat'] ?? resData['id'] ?? '').toString();
          if (newObatId == 'null') newObatId = '';
        }
        if (newObatId.isEmpty && isEdit) {
          newObatId = docId;
        }

        if (stockStr.isNotEmpty &&
            pharmacyId != null &&
            pharmacyId.isNotEmpty &&
            newObatId.isNotEmpty) {
          final stockVal = int.tryParse(stockStr) ?? 0;
          final apotekId = int.tryParse(pharmacyId) ?? 0;
          final parsedObatId = int.tryParse(newObatId);

          if (apotekId > 0 && parsedObatId != null && parsedObatId > 0) {
            final existingStockId = isEdit ? (fields['id_stok'] ?? '') : '';
            http.Response stokRes;
            if (existingStockId.isNotEmpty && existingStockId != 'null') {
              stokRes = await ApiClient.put('/stok-obat/$existingStockId', {
                'jumlah_stok': stockVal,
              }, token: token);
            } else {
              stokRes = await ApiClient.post('/stok-obat', {
                'id_apotek': apotekId,
                'id_obat': parsedObatId,
                'jumlah_stok': stockVal,
              }, token: token);
            }
            if (stokRes.statusCode != 200 && stokRes.statusCode != 201) {
              String stokErrMsg = 'Gagal simpan stok [${stokRes.statusCode}]';
              try {
                stokErrMsg = jsonDecode(stokRes.body)['message'] ?? stokErrMsg;
              } catch (_) {}
              throw Exception(stokErrMsg);
            }
          }
        }
        return true;
      } else {
        String errMsg = 'Gagal menyimpan [${res.statusCode}]';
        try {
          errMsg = jsonDecode(res.body)['message'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
