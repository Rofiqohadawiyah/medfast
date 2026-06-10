import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';

class AdminProdukPage extends StatefulWidget {
  const AdminProdukPage({super.key});

  @override
  State<AdminProdukPage> createState() => _AdminProdukPageState();
}

class _AdminProdukPageState extends State<AdminProdukPage> {
  List<dynamic> _products = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      final apotekId = user?.pharmacyId;
      final authService = AuthService();
      final token = await authService.token;

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token tidak ditemukan, silakan login ulang.'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      // Ambil daftar produk dari /obat
      final res = await ApiClient.get('/obat', token: token);
      if (res.statusCode != 200) {
        final errMsg = _tryParseError(res.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat produk: $errMsg'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _loading = false);
        }
        return;
      }

      final rawList = jsonDecode(res.body) as List<dynamic>;

      // Jika admin punya apotek, ambil juga stok untuk di-merge
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
          .where((item) => stokMap.containsKey(item['id_obat'])) // hanya obat apotek ini
          .map((item) {
        final idObat = item['id_obat'];
        final stokItem = stokMap[idObat];
        final int stockQty = ((stokItem?['jumlah_stok'] ?? stokItem?['stok'] ?? 0) as num).toInt();
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
      }).toList(); // stok 0 tetap tampil, apotek lain tidak tampil

      if (mounted) {
        setState(() {
          _products = list;
          _filtered = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memuat produk: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _loading = false);
      }
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

  void _filter(String query) {
    setState(() {
      _search = query.toLowerCase();
      _filtered = _products.where((p) {
        final name = (p['nama_obat'] ?? p['name'] ?? '')
            .toString()
            .toLowerCase();
        return name.contains(_search);
      }).toList();
    });
  }

  Future<void> _hapus(Map<String, dynamic> data) async {
    final idStok = data['id_stok']?.toString();
    final idObat = (data['id_obat'] ?? data['id'] ?? '').toString();

    final konfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hapus Obat Ini?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Anda akan menghapus data\nobat ${data['nama_obat'] ?? 'ini'}.\nTindakan ini tidak dapat\ndibatalkan.',
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC02B48),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Ya, Hapus', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (konfirm != true) return;

    try {
      final authService = AuthService();
      final token = await authService.token;

      // Langkah 1: Hapus stok-obat dulu (jika ada), agar tidak FK constraint error
      if (idStok != null && idStok.isNotEmpty) {
        debugPrint('[_hapus] DELETE /stok-obat/$idStok');
        await ApiClient.delete('/stok-obat/$idStok', token: token);
      }

      // Langkah 2: Hapus obat dari tabel utama
      if (idObat.isNotEmpty) {
        debugPrint('[_hapus] DELETE /obat/$idObat');
        final res = await ApiClient.delete('/obat/$idObat', token: token);
        if (res.statusCode == 200 || res.statusCode == 204) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Produk berhasil dihapus'),
                backgroundColor: AppColors.darkGreen,
              ),
            );
            _loadProducts();
          }
        } else {
          final errMsg = _tryParseError(res.body);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal hapus [${res.statusCode}]: $errMsg'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showForm([Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdukSheet(
        existing: existing, 
        onSaved: _loadProducts,
        onDelete: existing != null ? () {
          Navigator.pop(context);
          _hapus(existing);
        } : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalKategori = _products.map((e) => e['kategori'].toString()).where((e) => e.isNotEmpty).toSet().length;
    final int hampirHabis = _products.where((e) {
      final stok = int.tryParse(e['jumlah_stok']?.toString() ?? '0') ?? 0;
      return stok > 0 && stok < 15;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('MedFast Admin', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                    Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                  ],
                ),
                const SizedBox(height: 36),
                const Text('Tambah Obat Baru', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan detail informasi obat dengan\nlengkap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),

          // List & Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    color: AppColors.darkGreen,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        // Tambah Obat Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4A6B5D),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Tambah Obat', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          onPressed: () => _showForm(),
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: TextField(
                            onChanged: _filter,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.black45, size: 20),
                              hintText: 'Cari nama obat, kategori, atau kode...',
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Grid Stats
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard('Total\nProduk', '${_products.length}', Icons.medical_services_outlined, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                            _buildStatCard('Stok\nTerjual', '1.2k', Icons.trending_up, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                            _buildStatCard('Hampir\nHabis', '$hampirHabis', Icons.warning_amber_rounded, const Color(0xFFF5EBEB), Colors.red, isAlert: true),
                            _buildStatCard('Kategori', '$totalKategori', Icons.category_outlined, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // List Obat
                        if (_filtered.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('Belum ada produk.', style: TextStyle(color: Colors.black38, fontSize: 15)),
                            ),
                          )
                        else
                          ..._filtered.map((data) => _buildCard(data)).toList(),

                        const SizedBox(height: 24),
                        if (_filtered.isNotEmpty) _buildPagination(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bgColor, Color textColor, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: isAlert ? Border.all(color: Colors.red.withOpacity(0.2), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500, height: 1.2))),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> data) {
    final name = data['nama_obat'] ?? data['name'] ?? '-';
    final category = data['kategori'] ?? 'Umum';
    final idObat = data['id_obat'] ?? data['id'] ?? '-';
    final imageUrl = data['gambar'] ?? '';
    final int stock = (data['jumlah_stok'] ?? 0) as int;
    final bool hasStock = stock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 56, height: 56, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56, height: 56,
                color: const Color(0xFFEAF0FC),
                child: const Icon(Icons.medication, color: AppColors.darkGreen),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Kategori: $category', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                Text('ID: MED-${idObat.toString().padLeft(3, '0')}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                const SizedBox(height: 2),
                Text(
                  'Stok: $stock${hasStock ? '' : ' (kosong)'}',
                  style: TextStyle(
                    color: hasStock ? Colors.green : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.green, size: 20),
                onPressed: () => _showForm(data),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: hasStock ? Colors.redAccent : Colors.grey,
                  size: 20,
                ),
                onPressed: hasStock ? () => _hapus(data) : null,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pageBtn(Icons.chevron_left, false),
        _pageBtn('1', true),
        _pageBtn('2', false),
        _pageBtn('3', false),
        const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...', style: TextStyle(color: Colors.black54))),
        _pageBtn(Icons.chevron_right, false),
      ],
    );
  }

  Widget _pageBtn(dynamic content, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? AppColors.darkGreen : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? null : Border.all(color: Colors.black12),
      ),
      alignment: Alignment.center,
      child: content is IconData
          ? Icon(content, color: Colors.black54, size: 18)
          : Text(
              content.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
    );
  }
}

// ─── Bottom Sheet Tambah / Edit Produk ───────────────────────────────────────
class _ProdukSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;
  final VoidCallback? onDelete;
  const _ProdukSheet({this.existing, required this.onSaved, this.onDelete});

  @override
  State<_ProdukSheet> createState() => _ProdukSheetState();
}

class _ProdukSheetState extends State<_ProdukSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl,
      _priceCtrl,
      _imageCtrl,
      _descCtrl,
      _catCtrl,
      _stockCtrl;
  Uint8List? _imageBytes;
  bool _loading = false;

  bool get _isEdit => widget.existing != null;
  String get _docId =>
      (widget.existing?['id_obat'] ?? widget.existing?['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _nameCtrl = TextEditingController(
      text: d?['nama_obat'] ?? d?['name'] ?? '',
    );
    _priceCtrl = TextEditingController(
      text: (d?['harga'] ?? d?['price'])?.toString() ?? '',
    );
    _imageCtrl = TextEditingController(
      text: d?['gambar'] ?? d?['imageUrl'] ?? '',
    );
    _descCtrl = TextEditingController(
      text: d?['deskripsi'] ?? d?['description'] ?? '',
    );
    _catCtrl = TextEditingController(
      text: d?['kategori'] ?? d?['category'] ?? '',
    );
    _stockCtrl = TextEditingController(
      text: (d?['jumlah_stok'] ?? d?['stock'])?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _priceCtrl,
      _imageCtrl,
      _descCtrl,
      _catCtrl,
      _stockCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user == null) throw Exception('Sesi berakhir, login kembali.');
      final authService = AuthService();
      final token = await authService.token;
      if (token == null)
        throw Exception('Token tidak ditemukan, silakan login ulang.');

      final fields = <String, String>{
        'nama_obat': _nameCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'kategori': _catCtrl.text.trim(),
        'harga': _priceCtrl.text.trim(),
      };

      debugPrint(
        '[_simpan] Mengirim ke API: ${ApiClient.baseUrl}${_isEdit ? "/obat/$_docId" : "/obat"}',
      );
      debugPrint('[_simpan] Fields: $fields');
      debugPrint(
        '[_simpan] Gambar: ${_imageBytes != null ? "${_imageBytes!.length} bytes" : "tidak ada"}',
      );

      final streamed = await ApiClient.multipart(
        method: _isEdit ? 'PUT' : 'POST',
        endpoint: _isEdit ? '/obat/$_docId' : '/obat',
        fields: fields,
        imageBytes: _imageBytes,
        filename: _imageBytes != null
            ? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : null,
        token: token,
      );

      final res = await http.Response.fromStream(streamed);
      debugPrint('[_simpan] Status: ${res.statusCode}, Body: ${res.body}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        Map<String, dynamic> resData = {};
        try {
          resData = jsonDecode(res.body) as Map<String, dynamic>;
        } catch (_) {}

        // Coba semua kemungkinan struktur response API:
        // { data: { id_obat } }, { obat: { id_obat } }, { result: { id_obat } },
        // { id_obat }, { id }
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
          newObatId =
              (resData['id_obat'] ?? resData['id'] ?? '').toString();
          if (newObatId == 'null') newObatId = '';
        }
        if (newObatId.isEmpty && _isEdit) {
          newObatId = _docId;
        }
        debugPrint('[_simpan] ID obat berhasil: "$newObatId"');
        debugPrint('[_simpan] user.pharmacyId: "${user.pharmacyId}"');
        debugPrint('[_simpan] Full response body: ${res.body}');

        // Simpan stok hanya jika ada pharmacyId dan stok diisi
        final stockStr = _stockCtrl.text.trim();
        if (stockStr.isNotEmpty &&
            user.pharmacyId != null &&
            user.pharmacyId!.isNotEmpty &&
            newObatId.isNotEmpty) {
          final stockVal = int.tryParse(stockStr) ?? 0;
          final apotekId = int.tryParse(user.pharmacyId!) ?? 0;
          final parsedObatId = int.tryParse(newObatId);
          debugPrint('========== CEK STOK ==========');
          debugPrint('user.pharmacyId = ${user.pharmacyId}');
          debugPrint('apotekId        = $apotekId');
          debugPrint('parsedObatId    = $parsedObatId');
          debugPrint('stockVal        = $stockVal');
          debugPrint('==============================');
          if (apotekId > 0 && parsedObatId != null && parsedObatId > 0) {
            final existingStockId = widget.existing?['id_stok'];
            http.Response stokRes;
            if (existingStockId != null) {
              debugPrint(
                '[_simpan] PUT /stok-obat/$existingStockId stok=$stockVal',
              );
              stokRes = await ApiClient.put('/stok-obat/$existingStockId', {
                'jumlah_stok': stockVal,
              }, token: token);
            } else {
              debugPrint(
                '[_simpan] POST /stok-obat apotek=$apotekId obat=$parsedObatId stok=$stockVal',
              );
              stokRes = await ApiClient.post('/stok-obat', {
                'id_apotek': apotekId,
                'id_obat': parsedObatId,
                'jumlah_stok': stockVal,
              }, token: token);
            }
            debugPrint(
              '[_simpan] Stok response: ${stokRes.statusCode} ${stokRes.body}',
            );
            if (stokRes.statusCode != 200 && stokRes.statusCode != 201) {
              String stokErrMsg = 'Gagal simpan stok [${stokRes.statusCode}]';
              try {
                stokErrMsg =
                    jsonDecode(stokRes.body)['message'] ?? stokErrMsg;
              } catch (_) {}
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(stokErrMsg),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            }
          } else {
            debugPrint('[_simpan] SKIP stok: apotekId=$apotekId parsedObatId=$parsedObatId (salah satu <= 0 atau null)');
          }
        } else {
          debugPrint('[_simpan] SKIP stok: stockStr="$stockStr" pharmacyId="${user.pharmacyId}" newObatId="$newObatId"');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEdit ? 'Produk diperbarui!' : 'Produk ditambahkan!',
              ),
              backgroundColor: AppColors.darkGreen,
            ),
          );
          Navigator.pop(context);
          widget.onSaved();
        }
      } else {
        String errMsg = 'Gagal menyimpan [${res.statusCode}]';
        try {
          errMsg = jsonDecode(res.body)['message'] ?? errMsg;
        } catch (_) {}
        throw Exception(errMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImg = widget.existing?['gambar'] ?? widget.existing?['imageUrl'];
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Stack(
          children: [
            // Dark Green Header
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _isEdit ? 'Edit Data Obat' : 'Tambah Obat Baru',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // White Form Container
            Positioned(
              top: 80,
              left: 20,
              right: 20,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photo Area
                        Center(
                          child: Column(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: _pilihGambar,
                                    child: Container(
                                      width: 100, height: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.black12, width: 1.5),
                                      ),
                                      child: _imageBytes != null
                                          ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(_imageBytes!, fit: BoxFit.cover))
                                          : existingImg != null && existingImg.toString().isNotEmpty
                                              ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(existingImg, fit: BoxFit.cover))
                                              : const Icon(Icons.image_outlined, color: Colors.black26, size: 40),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -4, right: -4,
                                    child: GestureDetector(
                                      onTap: _pilihGambar,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: AppColors.darkGreen, shape: BoxShape.circle),
                                        child: const Icon(Icons.edit, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _isEdit ? 'Ubah Foto Obat' : 'Upload Foto Obat',
                                style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _field('Nama Obat', _nameCtrl, Icons.local_offer_outlined),
                        const SizedBox(height: 16),
                        _field('Kategori', _catCtrl, Icons.category_outlined, required: false, isDropdown: true),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _field('Harga (Rp)', _priceCtrl, Icons.money_outlined, keyboard: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(child: _field('Stok', _stockCtrl, Icons.inventory_2_outlined, keyboard: TextInputType.number, required: false)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field('Deskripsi', _descCtrl, Icons.description_outlined, required: false, maxLines: 4),
                        const SizedBox(height: 32),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: _loading ? null : _simpan,
                            icon: _loading ? const SizedBox() : const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                            label: _loading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(
                                    _isEdit ? 'Simpan Perubahan' : 'Simpan Data',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                          ),
                        ),

                        if (_isEdit && widget.onDelete != null) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: widget.onDelete,
                              child: const Text('Hapus Obat', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboard, bool required = true, int maxLines = 1, bool isDropdown = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.black54, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Tidak boleh kosong' : null : null,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
            suffixIcon: isDropdown ? const Icon(Icons.keyboard_arrow_down, color: Colors.black54) : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
