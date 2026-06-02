import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../utils/colors.dart';
import 'pilih_alamat_page.dart';

class AlamatSayaPage extends StatefulWidget {
  const AlamatSayaPage({super.key});

  @override
  State<AlamatSayaPage> createState() => _AlamatSayaPageState();
}

class _AlamatSayaPageState extends State<AlamatSayaPage> {
  bool _loading = false;

  Future<void> _updateAlamatInBackend(BuildContext context, String newAddress) async {
    setState(() => _loading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.userModel;
      if (user == null) return;

      final authService = AuthService();
      final token = await authService.token;

      // Update di backend API menggunakan PUT /profile
      final response = await ApiClient.put('/profile', {
        'nama': user.name,
        'no_hp': user.phone,
        'alamat': newAddress,
      }, token: token);

      if (response.statusCode == 200) {
        // Parse updated user data directly from response
        final responseBody = jsonDecode(response.body);
        final updatedData = responseBody['data'];
        final updatedUser = UserModel.fromJson(updatedData);

        // Update local SharedPreferences cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(updatedData));

        // Update AuthProvider state
        authProvider.updateUserFromModel(updatedUser);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newAddress.isEmpty ? 'Alamat berhasil dihapus!' : 'Alamat berhasil disimpan!'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
        }
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui alamat';
        throw Exception(msg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _tambahAlamat(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const PilihAlamatPage()),
    );

    if (result != null && context.mounted) {
      final address = result['address'] as String;
      await _updateAlamatInBackend(context, address);
    }
  }

  Future<void> _hapusAlamat(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Alamat?'),
        content: const Text('Apakah Anda yakin ingin menghapus alamat?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await _updateAlamatInBackend(context, '');
    }
  }

  Future<void> _editAlamat(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const PilihAlamatPage()),
    );

    if (result != null && context.mounted) {
      final address = result['address'] as String;
      await _updateAlamatInBackend(context, address);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final address = user?.alamat ?? '';

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 24),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Alamat Saya',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol Tambah Alamat (hanya muncul jika alamat masih kosong)
          if (address.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkGreen,
                    side: const BorderSide(color: AppColors.darkGreen, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text(
                    '+ Tambah Alamat Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _loading ? null : () => _tambahAlamat(context),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Daftar Alamat dari Local API
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
              : address.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.location_off, size: 64, color: Colors.black26),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada alamat tersimpan',
                          style: TextStyle(color: Colors.black38, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap tombol di atas untuk menambah alamat',
                          style: TextStyle(color: Colors.black26, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.lightGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.location_on, color: AppColors.darkGreen, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Alamat Utama',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    address,
                                    style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.5),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: AppColors.darkGreen, size: 22),
                              tooltip: 'Edit Alamat',
                              onPressed: _loading ? null : () => _editAlamat(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                              onPressed: _loading ? null : () => _hapusAlamat(context),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
