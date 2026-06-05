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

  void _showApotekInfoDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user?.pharmacyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Apotek tidak ditemukan untuk admin ini.')),
      );
      return;
    }

    final namaApotek = _apotekData?['nama_apotek'] ?? '-';
    final alamat = _apotekData?['alamat'] ?? '-';
    final lat = (_apotekData?['latitude'] ?? _apotekData?['lat'] ?? '-').toString();
    final lng = (_apotekData?['longitude'] ?? _apotekData?['lng'] ?? '-').toString();
    final jam = _apotekData?['jam_operasional'] ?? _apotekData?['jam_kerja'] ?? '-';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: const [
            Icon(Icons.location_on, color: AppColors.darkGreen),
            SizedBox(width: 8),
            Text('Info Apotek', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow(Icons.store_outlined, 'Nama Apotek', namaApotek),
              const Divider(height: 20),
              _infoRow(Icons.place_outlined, 'Alamat', alamat),
              const Divider(height: 20),
              _infoRow(Icons.my_location_outlined, 'Latitude', lat),
              const Divider(height: 20),
              _infoRow(Icons.my_location_outlined, 'Longitude', lng),
              const Divider(height: 20),
              _infoRow(Icons.access_time_outlined, 'Jam Operasional', jam),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.darkGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.darkGreen, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Data Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 28), // Balance the back arrow
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: 120, height: 120,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.person_outline, size: 70, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'Naira Fahira',
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _apotekData?['nama_apotek'] ?? 'Apotek Mitra',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Menus
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Ubah data akun admin',
                    onTap: _showEditProfileDialog,
                  ),
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
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Kelola lokasi apotek',
                    onTap: _showApotekInfoDialog,
                  ),
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
                    isLogout: true,
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
    bool isLogout = false,
  }) {
    final bgColor = isLogout ? const Color(0xFFF5EBEB) : const Color(0xFFEAF5F0);
    final iconColor = isLogout ? const Color(0xFFC02B48) : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87, size: 24),
          ],
        ),
      ),
    );
  }
}
