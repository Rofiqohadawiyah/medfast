import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/alamat_saya_controller.dart';
import '../utils/colors.dart';
import 'pilih_alamat_page.dart';

class AlamatSayaPage extends StatelessWidget {
  const AlamatSayaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AlamatSayaController(),
      child: const _AlamatSayaUI(),
    );
  }
}

class _AlamatSayaUI extends StatefulWidget {
  const _AlamatSayaUI();

  @override
  State<_AlamatSayaUI> createState() => _AlamatSayaUIState();
}

class _AlamatSayaUIState extends State<_AlamatSayaUI> {
  Future<void> _updateAlamat(BuildContext context, String newAddress) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final controller = context.read<AlamatSayaController>();
    final updatedUser = await controller.updateAlamat(user, newAddress);

    if (context.mounted) {
      if (updatedUser != null) {
        authProvider.updateUserFromModel(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.successMessage!),
            backgroundColor: AppColors.darkGreen,
          ),
        );
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      controller.clearMessages();
    }
  }

  Future<void> _tambahAlamat(BuildContext context) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const PilihAlamatPage()),
    );

    if (result != null && context.mounted) {
      final address = result['address'] as String;
      await _updateAlamat(context, address);
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
      await _updateAlamat(context, ''); // string kosong sebagai penanda hapus
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final controller = context.watch<AlamatSayaController>();

    final address = user?.alamat ?? '';
    final hasAddress = address.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 56, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Alamat Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (controller.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(right: 20),
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: hasAddress
                ? _buildAddressCard(context, address)
                : _buildEmptyState(context),
          ),

          // Tombol Tambah Alamat di Bawah
          if (!hasAddress && !controller.isLoading)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => _tambahAlamat(context),
                  icon: const Icon(Icons.add_location_alt, color: Colors.white),
                  label: const Text(
                    'Tambah Alamat Baru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.location_off_outlined, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada alamat pengiriman',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan alamat agar pesanan\nbisa diantar ke tempatmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String address) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Alamat Utama',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.darkGreen, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkGreen.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: AppColors.lightGreen, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.home, color: AppColors.darkGreen, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Rumah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(12)),
                    child: const Text('Utama', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              Text(address, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _hapusAlamat(context),
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Hapus', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _tambahAlamat(context),
                    icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                    label: const Text('Ubah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
