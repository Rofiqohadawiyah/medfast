import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/admin_profil_controller.dart';
import '../utils/colors.dart';
import 'welcome_page.dart';
import 'password_page.dart';

class AdminProfilPage extends StatelessWidget {
  const AdminProfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AdminProfilController(),
      child: const _AdminProfilUI(),
    );
  }
}

class _AdminProfilUI extends StatefulWidget {
  const _AdminProfilUI();

  @override
  State<_AdminProfilUI> createState() => _AdminProfilUIState();
}

class _AdminProfilUIState extends State<_AdminProfilUI> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      context.read<AdminProfilController>().fetchApotekDetails(user?.pharmacyId);
    });
  }

  void _showEditProfileDialog() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;
    
    final controller = context.read<AdminProfilController>();

    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return ChangeNotifierProvider.value(
          value: controller,
          child: Consumer<AdminProfilController>(
            builder: (context, controller, _) {
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
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: controller.isLoading ? null : () async {
                    if (!formKey.currentState!.validate()) return;

                    final updatedUser = await controller.updateProfile(
                      currentUser: user!,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                    );

                    if (updatedUser != null && context.mounted) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      authProvider.updateUserFromModel(updatedUser);

                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profil admin berhasil diperbarui'), backgroundColor: AppColors.darkGreen),
                        );
                      }
                    } else if (controller.errorMessage != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        ));
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

    final controller = context.read<AdminProfilController>();

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
              _infoRow(Icons.store_outlined, 'Nama Apotek', controller.getApotekName()),
              const Divider(height: 20),
              _infoRow(Icons.place_outlined, 'Alamat', controller.getApotekAddress()),
              const Divider(height: 20),
              _infoRow(Icons.my_location_outlined, 'Latitude', controller.getApotekLat()),
              const Divider(height: 20),
              _infoRow(Icons.my_location_outlined, 'Longitude', controller.getApotekLng()),
              const Divider(height: 20),
              _infoRow(Icons.access_time_outlined, 'Jam Operasional', controller.getApotekJam()),
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
    final controller = context.watch<AdminProfilController>();

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
                    controller.getApotekName() != '-' ? controller.getApotekName() : 'Apotek Mitra',
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
