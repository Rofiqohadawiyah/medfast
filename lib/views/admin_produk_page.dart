import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../controllers/admin_produk_controller.dart';
import '../utils/colors.dart';

class AdminProdukPage extends StatelessWidget {
  const AdminProdukPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final user = Provider.of<AuthProvider>(context, listen: false).userModel;
        return AdminProdukController()..loadProducts(user?.pharmacyId);
      },
      child: const _AdminProdukPageUI(),
    );
  }
}

class _AdminProdukPageUI extends StatelessWidget {
  const _AdminProdukPageUI({super.key});

  void _showForm(BuildContext context, [Map<String, dynamic>? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProdukSheet(
        existing: existing,
        parentContext: context,
      ),
    );
  }

  void _hapus(BuildContext context, Map<String, dynamic> data) async {
    final controller = context.read<AdminProdukController>();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    
    final konfirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined, color: Color(0xFFC02B48), size: 48),
            const SizedBox(height: 16),
            const Text(
              'Hapus Obat Ini?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Apakah Anda yakin ingin menghapus obat "${data['nama_obat'] ?? 'ini'}"?',
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

    final success = await controller.hapusProduk(data);
    if (success) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: AppColors.darkGreen),
        );
        controller.loadProducts(user?.pharmacyId);
      }
    } else {
      if (context.mounted && controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminProdukController>();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;

    final int totalKategori = controller.products
        .map((e) => e['kategori'].toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .length;
    final int hampirHabis = controller.products.where((e) {
      final stok = int.tryParse(e['jumlah_stok']?.toString() ?? '0') ?? 0;
      return stok > 0 && stok < 15;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: controller.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
          : RefreshIndicator(
              onRefresh: () => controller.loadProducts(user?.pharmacyId),
              color: AppColors.darkGreen,
              child: ListView(
                padding: EdgeInsets.zero,
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
                            Text(
                              'MedFast Admin',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            Icon(Icons.notifications_none_outlined, color: Colors.white, size: 22),
                          ],
                        ),
                        const SizedBox(height: 36),
                        const Text(
                          'Kelola Produk',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cari, tambah, edit, atau hapus produk apotek kamu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // List & Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (controller.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(controller.errorMessage!, style: const TextStyle(color: Colors.red)),
                          ),
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
                          onPressed: () => _showForm(context),
                        ),
                        const SizedBox(height: 16),

                        // Search Bar
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            onChanged: controller.onSearchChanged,
                            decoration: const InputDecoration(
                              icon: Icon(Icons.search, color: Colors.black45, size: 20),
                              hintText: 'Cari nama obat, kategori, atau kode...',
                              hintStyle: TextStyle(color: Colors.black38, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Grid Stats
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.3,
                          children: [
                            _buildStatCard('Total\nProduk', '${controller.products.length}', Icons.medical_services_outlined, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                            _buildStatCard('Stok\nTerjual', '1.2k', Icons.trending_up, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                            _buildStatCard('Hampir\nHabis', '$hampirHabis', Icons.warning_amber_rounded, const Color(0xFFF5EBEB), Colors.red, isAlert: true),
                            _buildStatCard('Kategori', '$totalKategori', Icons.category_outlined, const Color(0xFFEAF5F8), const Color(0xFF1E4B3B)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // List Obat
                        if (controller.filtered.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Text('Belum ada produk.', style: TextStyle(color: Colors.black38, fontSize: 15)),
                            ),
                          )
                        else
                          ...controller.filtered.map((data) => _buildCard(context, data)).toList(),

                        const SizedBox(height: 24),
                        if (controller.filtered.isNotEmpty) _buildPagination(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
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
              Expanded(
                child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500, height: 1.2)),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Map<String, dynamic> data) {
    final name = data['nama_obat'] ?? data['name'] ?? '-';
    final category = data['kategori'] ?? 'Umum';
    final idObat = data['id_obat'] ?? data['id'] ?? '-';
    final imageUrl = data['gambar'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56,
                height: 56,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Kategori: $category', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                Text('ID: MED-${idObat.toString().padLeft(3, '0')}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.green, size: 20),
                onPressed: () => _showForm(context, data),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _hapus(context, data),
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
              style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontSize: 13, fontWeight: isActive ? FontWeight.bold : FontWeight.normal),
            ),
    );
  }
}

// ── Bottom Sheet Tambah / Edit Produk ──
class _ProdukSheet extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final BuildContext parentContext;
  const _ProdukSheet({this.existing, required this.parentContext});

  @override
  State<_ProdukSheet> createState() => _ProdukSheetState();
}

class _ProdukSheetState extends State<_ProdukSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _priceCtrl, _imageCtrl, _descCtrl, _catCtrl, _stockCtrl;
  Uint8List? _imageBytes;
  bool _loading = false;

  final List<String> _kategoriList = ['Pil', 'Suplemen', 'Antibiotik', 'Resep Dokter'];

  bool get _isEdit => widget.existing != null;
  String get _docId => (widget.existing?['id_obat'] ?? widget.existing?['id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    _nameCtrl = TextEditingController(text: d?['nama_obat'] ?? d?['name'] ?? '');
    _priceCtrl = TextEditingController(text: (d?['harga'] ?? d?['price'])?.toString() ?? '');
    _imageCtrl = TextEditingController(text: d?['gambar'] ?? d?['imageUrl'] ?? '');
    _descCtrl = TextEditingController(text: d?['deskripsi'] ?? d?['description'] ?? '');
    _catCtrl = TextEditingController(text: d?['kategori'] ?? d?['category'] ?? '');
    if (_catCtrl.text.isNotEmpty && !_kategoriList.contains(_catCtrl.text)) {
      _kategoriList.add(_catCtrl.text);
    }
    _stockCtrl = TextEditingController(text: (d?['jumlah_stok'] ?? d?['stock'])?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _descCtrl.dispose();
    _catCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihGambar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    
    final controller = widget.parentContext.read<AdminProdukController>();
    final user = Provider.of<AuthProvider>(widget.parentContext, listen: false).userModel;
    
    final fields = <String, String>{
      'nama_obat': _nameCtrl.text.trim(),
      'deskripsi': _descCtrl.text.trim(),
      'kategori': _catCtrl.text.trim(),
      'harga': _priceCtrl.text.trim(),
    };
    
    if (_isEdit && widget.existing?['id_stok'] != null) {
      fields['id_stok'] = widget.existing!['id_stok'].toString();
    }

    final success = await controller.simpanProduk(
      isEdit: _isEdit,
      docId: _docId,
      fields: fields,
      imageBytes: _imageBytes,
      stockStr: _stockCtrl.text.trim(),
      pharmacyId: user?.pharmacyId,
    );

    if (mounted) {
      setState(() => _loading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Produk diperbarui!' : 'Produk ditambahkan!'), backgroundColor: AppColors.darkGreen),
        );
        Navigator.pop(context);
        controller.loadProducts(user?.pharmacyId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: ${controller.errorMessage}'), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 5)),
        );
      }
    }
  }

  void _hapusFromForm() async {
     Navigator.pop(context);
     final controller = widget.parentContext.read<AdminProdukController>();
     final user = Provider.of<AuthProvider>(widget.parentContext, listen: false).userModel;
     
     final success = await controller.hapusProduk(widget.existing!);
     if (success && widget.parentContext.mounted) {
         ScaffoldMessenger.of(widget.parentContext).showSnackBar(
           const SnackBar(content: Text('Produk berhasil dihapus'), backgroundColor: AppColors.darkGreen),
         );
         controller.loadProducts(user?.pharmacyId);
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
                                      width: 100,
                                      height: 100,
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
                                    bottom: -4,
                                    right: -4,
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
                              Text(_isEdit ? 'Ubah Foto Obat' : 'Upload Foto Obat', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        _field('Nama Obat', _nameCtrl, Icons.local_offer_outlined),
                        const SizedBox(height: 16),
                        _field('Kategori', _catCtrl, Icons.category_outlined, required: false, isDropdown: true, dropdownItems: _kategoriList),
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
                                : Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Data', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),

                        if (_isEdit) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: _hapusFromForm,
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

  Widget _field(
    String label, TextEditingController ctrl, IconData icon, {
    TextInputType? keyboard, bool required = true, int maxLines = 1,
    bool isDropdown = false, List<String>? dropdownItems,
  }) {
    final decoration = InputDecoration(
      hintText: 'Pilih $label',
      hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.darkGreen, width: 1.5)),
    );

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
          decoration: decoration.copyWith(
            hintText: 'Masukkan $label',
            suffixIcon: (isDropdown && dropdownItems != null)
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                    onSelected: (String value) {
                      ctrl.text = value;
                    },
                    itemBuilder: (BuildContext context) {
                      return dropdownItems.map((String choice) {
                        return PopupMenuItem<String>(value: choice, child: Text(choice));
                      }).toList();
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
