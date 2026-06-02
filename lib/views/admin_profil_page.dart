import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'welcome_page.dart';
import 'password_page.dart';

class AdminProfilPage extends StatefulWidget {
  const AdminProfilPage({super.key});

  @override
  State<AdminProfilPage> createState() => _AdminProfilPageState();
}

class _AdminProfilPageState extends State<AdminProfilPage> {
  bool _loading = false;
  Map<String, dynamic>? _apotekData;

  @override
  void initState() {
    super.initState();
    _fetchApotekDetails();
  }

  Future<void> _fetchApotekDetails() async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user?.pharmacyId == null) return;

    try {
      final res = await ApiClient.get('/apotek');
      if (res.statusCode == 200) {
        final List<dynamic> list = jsonDecode(res.body);
        final match = list.firstWhere(
          (a) => a['id_apotek']?.toString() == user!.pharmacyId,
          orElse: () => null,
        );
        if (mounted && match != null) {
          setState(() {
            _apotekData = match;
          });
        }
      }
    } catch (_) {}
  }

  void _showEditProfileDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Ubah Profil Admin', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Admin'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'No. Handphone'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'No. HP tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => _loading = true);
                  try {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final authService = AuthService();
                    final token = await authService.token;

                    final response = await ApiClient.put(
                      '/profile',
                      {
                        'nama': nameCtrl.text.trim(),
                        'no_hp': phoneCtrl.text.trim(),
                      },
                      token: token,
                    );

                    if (response.statusCode == 200) {
                      final responseBody = jsonDecode(response.body);
                      final updatedData = responseBody['data'];
                      final updatedUser = UserModel.fromJson(updatedData);

                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('user_data', jsonEncode(updatedData));

                      authProvider.updateUserFromModel(updatedUser);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil admin berhasil diperbarui'), backgroundColor: AppColors.darkGreen),
                        );
                      }
                    } else {
                      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  } finally {
                    setDialogState(() => _loading = false);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showEditApotekDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user?.pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Apotek tidak ditemukan untuk admin ini.')),
      );
      return;
    }

    final namaApotekCtrl = TextEditingController(text: _apotekData?['nama_apotek'] ?? '');
    final alamatCtrl = TextEditingController(text: _apotekData?['alamat'] ?? '');
    final latCtrl = TextEditingController(text: (_apotekData?['latitude'] ?? _apotekData?['lat'] ?? '').toString());
    final lngCtrl = TextEditingController(text: (_apotekData?['longitude'] ?? _apotekData?['lng'] ?? '').toString());
    final jamCtrl = TextEditingController(text: _apotekData?['jam_operasional'] ?? _apotekData?['jam_kerja'] ?? '08:00 - 21:00');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Kelola Lokasi & Apotek', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: namaApotekCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Apotek'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama apotek tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: alamatCtrl,
                      decoration: const InputDecoration(labelText: 'Alamat Apotek'),
                      maxLines: 2,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Alamat tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latCtrl,
                            decoration: const InputDecoration(labelText: 'Latitude'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lngCtrl,
                            decoration: const InputDecoration(labelText: 'Longitude'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: jamCtrl,
                      decoration: const InputDecoration(labelText: 'Jam Operasional', hintText: 'Misal: 08:00 - 21:00'),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Jam operasional tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loading ? null : () async {
                  if (!formKey.currentState!.validate()) return;
                  setDialogState(() => _loading = true);
                  try {
                    final response = await ApiClient.put(
                      '/apotek/${user!.pharmacyId}',
                      {
                        'nama_apotek': namaApotekCtrl.text.trim(),
                        'alamat': alamatCtrl.text.trim(),
                        'latitude': latCtrl.text.trim(),
                        'longitude': lngCtrl.text.trim(),
                        'jam_operasional': jamCtrl.text.trim(),
                      },
                    );

                    if (response.statusCode == 200) {
                      await _fetchApotekDetails();
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data apotek berhasil diperbarui'), backgroundColor: AppColors.darkGreen),
                        );
                      }
                    } else {
                      throw Exception(jsonDecode(response.body)['message'] ?? 'Gagal memperbarui apotek');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.redAccent),
                      );
                    }
                  } finally {
                    setDialogState(() => _loading = false);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Profile Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.admin_panel_settings_rounded, size: 70, color: AppColors.darkGreen),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Admin',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _apotekData?['nama_apotek'] ?? 'Apotek Mitra',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Menus
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Ubah Data Akun Admin',
                    onTap: _showEditProfileDialog,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Kelola Lokasi Apotek',
                    onTap: _showEditApotekDialog,
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PasswordPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const WelcomePage()),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkGreen, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black54, size: 28),
          ],
        ),
      ),
    );
  }
}
