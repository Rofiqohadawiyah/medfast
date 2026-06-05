import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'register_pages.dart';
import 'register_admin_page.dart' as admin_page;
import 'login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, left: 32, right: 32, bottom: 50),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Daftar Akun',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Pilih jenis akun yang ingin digunakan untuk mendaftar.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            // Pilihan Role
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Pelanggan
                  _roleCard(
                    context,
                    icon: Icons.person_outline,
                    title: 'Pelanggan',
                    subtitle: 'Masuk sebagai pelanggan untuk memesan obat',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPelangganPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Admin/Apotek
                  _roleCard(
                    context,
                    icon: Icons.storefront_outlined,
                    title: 'Apotek / Admin',
                    subtitle: 'Masuk sebagai admin untuk mengelola apotek',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const admin_page.RegisterAdminPage()),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.linkColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 30, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black45,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black54),
          ],
        ),
      ),
    );
  }
}
