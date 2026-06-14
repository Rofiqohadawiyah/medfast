import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/data_pribadi_controller.dart';
import '../utils/colors.dart';

class DataPribadiPage extends StatelessWidget {
  const DataPribadiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DataPribadiController(),
      child: const _DataPribadiUI(),
    );
  }
}

class _DataPribadiUI extends StatefulWidget {
  const _DataPribadiUI();

  @override
  State<_DataPribadiUI> createState() => _DataPribadiUIState();
}

class _DataPribadiUIState extends State<_DataPribadiUI> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    _nameController.text = user?.name ?? '';
    _phoneController.text = user?.phone ?? '';
    _emailController.text = user?.email ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan Nomor Handphone tidak boleh kosong')),
      );
      return;
    }

    final controller = context.read<DataPribadiController>();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userModel;
    if (user == null) return;

    final updatedUser = await controller.updateProfile(user, name, phone);

    if (context.mounted) {
      if (updatedUser != null) {
        authProvider.updateUserFromModel(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.successMessage!), backgroundColor: AppColors.darkGreen),
        );
        Navigator.pop(context);
      } else if (controller.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
        );
      }
      controller.clearMessages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DataPribadiController>();

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: Column(
        children: [

          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Data Pribadi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightGreen, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Center(
                        child: Icon(Icons.person, size: 50, color: Colors.black26),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.darkGreen,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),


          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildInputField(
                    label: 'Nama Lengkap',
                    icon: Icons.person_outline,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Nomor Handphone',
                    icon: Icons.phone_android_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    label: 'Email',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    enabled: false,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: controller.isLoading ? null : _handleSave,
                      child: controller.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(
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
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? Colors.white : Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (enabled)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 16,
              color: enabled ? Colors.black87 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? AppColors.darkGreen : Colors.black38),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
