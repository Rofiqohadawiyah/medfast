import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../utils/colors.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'welcome_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  IO.Socket? _socket;

  @override
  void initState() {
    super.initState();
    _initPresenceSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }

  void _initPresenceSocket() {
    final rawUrl = ApiClient.baseUrl;
    final socketUrl = rawUrl.substring(0, rawUrl.lastIndexOf('/api'));

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        _socket!.emit('register_presence', user.uid);
      }
    });
  }

  void _triggerRefresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 56,
              left: 24,
              right: 24,
              bottom: 28,
            ),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WelcomePage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Icon(
                        Icons.logout,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Halo, ${user?.name ?? 'Admin'}! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Kelola produk apotek kamu di sini.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Judul + Tombol Tambah
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Produk',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Tambah',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showTambahProdukSheet(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // List Produk dari Local API
          Expanded(
            child: FutureBuilder<http.Response>(
              future: ApiClient.get('/obat'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("API Error: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Terjadi kesalahan: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.darkGreen,
                    ),
                  );
                }

                if (snapshot.data == null || snapshot.data!.statusCode != 200) {
                  return const Center(
                    child: Text('Gagal memuat produk dari server lokal'),
                  );
                }

                final List<dynamic> docs = jsonDecode(snapshot.data!.body);
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.black26,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada produk.',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        Text(
                          'Tap tombol Tambah untuk mulai.',
                          style: TextStyle(color: Colors.black26, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final data = docs[i] as Map<String, dynamic>;
                      final docId = (data['id_obat'] ?? data['id'] ?? '')
                          .toString();
                      return _ProductCard(
                        docId: docId,
                        data: data,
                        onRefresh: _triggerRefresh,
                      );
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showTambahProdukSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TambahProdukSheet(onRefresh: _triggerRefresh),
    );
  }
}

// ─── Kartu produk per item ────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;
  const _ProductCard({
    required this.docId,
    required this.data,
    required this.onRefresh,
  });

  Future<void> _hapus(BuildContext context) async {
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Produk?'),
        content: Text(
          'Yakin ingin menghapus "${data['nama_obat'] ?? data['name'] ?? 'obat'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (konfirm == true) {
      try {
        final authService = AuthService();
        final token = await authService.token;

        final response = await ApiClient.delete('/obat/$docId', token: token);
        if (response.statusCode == 200) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil dihapus')),
            );
            onRefresh();
          }
        } else {
          throw Exception(
            jsonDecode(response.body)['message'] ?? 'Gagal menghapus produk',
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $e')));
        }
      }
    }
  }

  void _edit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TambahProdukSheet(
        docId: docId,
        existingData: data,
        onRefresh: onRefresh,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = data['nama_obat'] ?? data['name'] ?? '-';
    final price = data['harga'] ?? data['price'] ?? 0;
    final stock = data['jumlah_stok'] ?? data['stock'];
    final category = data['kategori'] ?? data['category'];
    final description = data['deskripsi'] ?? data['description'];
    final imageUrl = data['gambar'] ?? data['imageUrl'] ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 64,
                height: 64,
                color: AppColors.lightGreen,
                child: const Icon(Icons.medication, color: AppColors.darkGreen),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'Rp $price',
                      style: const TextStyle(
                        color: Color(0xFF4299E1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (stock != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Stok: $stock',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                if (category != null && category.toString().isNotEmpty)
                  Text(
                    category,
                    style: const TextStyle(
                      color: AppColors.darkGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (description != null)
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          // Aksi
          Column(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.darkGreen,
                  size: 20,
                ),
                onPressed: () => _edit(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: () => _hapus(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet Tambah / Edit Produk ───────────────────────────────────────
class _TambahProdukSheet extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;
  final VoidCallback? onRefresh;
  const _TambahProdukSheet({this.docId, this.existingData, this.onRefresh});

  @override
  State<_TambahProdukSheet> createState() => _TambahProdukSheetState();
}

class _TambahProdukSheetState extends State<_TambahProdukSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  Uint8List? _imageBytes;
  bool _loading = false;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.existingData;
    _nameCtrl.text = d?['nama_obat'] ?? d?['name'] ?? '';
    _priceCtrl.text = (d?['harga'] ?? d?['price'])?.toString() ?? '';
    _imageCtrl.text = d?['gambar'] ?? d?['imageUrl'] ?? '';
    _descCtrl.text = d?['deskripsi'] ?? d?['description'] ?? '';
    _categoryCtrl.text = d?['kategori'] ?? d?['category'] ?? '';
    _stockCtrl.text = (d?['jumlah_stok'] ?? d?['stock'])?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    _categoryCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.userModel;

      if (user == null) {
        throw Exception("Sesi login berakhir. Silakan login kembali.");
      }

      final authService = AuthService();
      final token = await authService.token;

      // Payload data fields
      final fields = <String, String>{
        'nama_obat': _nameCtrl.text.trim(),
        'deskripsi': _descCtrl.text.trim(),
        'kategori': _categoryCtrl.text.trim(),
        'harga': _priceCtrl.text.trim(),
      };

      final String method = _isEdit ? 'PUT' : 'POST';
      final String endpoint = _isEdit ? '/obat/${widget.docId}' : '/obat';

      final streamedResponse = await ApiClient.multipart(
        method: method,
        endpoint: endpoint,
        fields: fields,
        imageBytes: _imageBytes,
        filename: _imageBytes != null
            ? 'product_${DateTime.now().millisecondsSinceEpoch}.jpg'
            : null,
        token: token,
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final dynamic dataBlock = responseData['data'];
        String newObatId = '';
        if (dataBlock != null && dataBlock is Map) {
          newObatId = (dataBlock['id_obat'] ?? dataBlock['id'] ?? '')
              .toString();
        }
        if (newObatId.isEmpty) {
          newObatId = (responseData['id_obat'] ?? responseData['id'] ?? '')
              .toString();
        }
        if (newObatId.isEmpty && _isEdit) {
          newObatId = widget.docId ?? '';
        }

        // Menyimpan / memperbarui stok obat jika diinput
        final stockStr = _stockCtrl.text.trim();
        if (stockStr.isNotEmpty &&
            user.pharmacyId != null &&
            newObatId.isNotEmpty) {
          final stockVal = int.tryParse(stockStr) ?? 0;
          final apotekId = int.tryParse(user.pharmacyId!) ?? 0;
          final parsedObatId = int.tryParse(newObatId);
          if (apotekId > 0 && parsedObatId != null && parsedObatId > 0) {
            // Since this page loads from global /obat, we check if there's an existing stock for this apotek and obat.
            // But we don't have id_stok directly, so let's try to query it first.
            int? existingStockId;
            try {
              final stockCheckRes = await ApiClient.get(
                '/stok-obat?id_apotek=$apotekId',
                token: token,
              );
              if (stockCheckRes.statusCode == 200) {
                final List<dynamic> stockList = jsonDecode(stockCheckRes.body);
                final matched = stockList.firstWhere(
                  (s) =>
                      (s['id_obat']?.toString() == newObatId ||
                      (s['obat']?['id_obat']?.toString() == newObatId)),
                  orElse: () => null,
                );
                if (matched != null) {
                  existingStockId = int.tryParse(
                    matched['id_stok']?.toString() ?? '',
                  );
                }
              }
            } catch (_) {}

            if (existingStockId != null) {
              await ApiClient.put('/stok-obat/$existingStockId', {
                'stok': stockVal,
              }, token: token);
            } else {
              // Panggil API POST /api/stok-obat untuk membuat/update stok
              await ApiClient.post('/stok-obat', {
                'id_apotek': apotekId,
                'id_obat': parsedObatId,
                'stok': stockVal,
              }, token: token);
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEdit
                    ? 'Produk berhasil diperbarui!'
                    : 'Produk berhasil ditambahkan!',
              ),
            ),
          );
          Navigator.pop(context);
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
        }
      } else {
        final errorMsg =
            jsonDecode(response.body)['message'] ?? 'Gagal menyimpan produk';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("ERROR saat menyimpan produk: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existingImg =
        widget.existingData?['gambar'] ?? widget.existingData?['imageUrl'];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEdit ? 'Edit Produk' : 'Tambah Produk Baru',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _field('Nama Produk', _nameCtrl, Icons.medication_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        'Harga (Rp)',
                        _priceCtrl,
                        Icons.attach_money,
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        'Stok',
                        _stockCtrl,
                        Icons.inventory_2_outlined,
                        keyboard: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _field('Kategori', _categoryCtrl, Icons.category_outlined),
                const SizedBox(height: 20),

                // Image Picker Area
                const Text(
                  'Foto Produk',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pilihGambar,
                  child: Container(
                    width: double.infinity,
                    height: 140,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.darkGreen.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: _imageBytes != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : existingImg != null &&
                              existingImg.toString().isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              existingImg,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.darkGreen,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap untuk pilih foto dari galeri',
                                style: TextStyle(
                                  color: AppColors.darkGreen,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                _field(
                  'Atau gunakan URL Gambar',
                  _imageCtrl,
                  Icons.link_outlined,
                  required: false,
                ),
                const SizedBox(height: 12),
                _field(
                  'Deskripsi',
                  _descCtrl,
                  Icons.description_outlined,
                  required: false,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _loading ? null : _simpan,
                    child: _loading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType? keyboard,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: required
          ? (v) => (v == null || v.trim().isEmpty)
                ? '$label tidak boleh kosong'
                : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.darkGreen),
        filled: true,
        fillColor: AppColors.lightGreen.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.5),
        ),
      ),
    );
  }
}
