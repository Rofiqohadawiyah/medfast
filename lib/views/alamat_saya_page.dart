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
      await _updateAlamat(context, '');
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

          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              color: AppColors.darkGreen,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Text(
                  'Alamat Saya',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (controller.isLoading)
                  const Positioned(
                    right: 24,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              children: [
                const SizedBox(height: 16),

                InkWell(
                  onTap: () => _tambahAlamat(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.darkGreen,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkGreen.withOpacity(0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gunakan Lokasi Saat ini',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Alamat akan otomatis terisi berdasarkan lokasi anda',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 28,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: TextButton.icon(
                    onPressed: () => _tambahAlamat(context),
                    icon: const Icon(
                      Icons.add,
                      color: Color(0xFF15975F),
                      size: 24,
                    ),
                    label: const Text(
                      'Tambah Alamat',
                      style: TextStyle(
                        color: Color(0xFF15975F),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (hasAddress)
                  _buildAddressCard(context, address)
                else
                  _buildEmptyState(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.darkGreen.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.location_off_outlined,
              size: 48,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada alamat pengiriman',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan alamat agar pesanan\nbisa diantar ke tempatmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, String address) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Alamat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'ubah') {
                    _tambahAlamat(context);
                  } else if (value == 'hapus') {
                    _hapusAlamat(context);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem<String>(
                    value: 'ubah',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20, color: Colors.black87),
                        SizedBox(width: 8),
                        Text('Ubah'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'hapus',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
