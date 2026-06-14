import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../utils/colors.dart';
import 'admin_main_screen.dart';
import 'login_page.dart';

class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key});

  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _kodeApotekCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _cekLoading = false;
  String? _namaApotekFound;

  @override
  void dispose() {
    _kodeApotekCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }


  Future<void> _cekKodeApotek() async {
    final kode = _kodeApotekCtrl.text.trim();
    if (kode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode apotek terlebih dahulu.')),
      );
      return;
    }
    setState(() {
      _cekLoading = true;
      _namaApotekFound = null;
    });
    try {
      final res = await ApiClient.get('/apotek');
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List<dynamic>;
        final match = list.firstWhere(
          (a) =>
              (a['kode_apotek'] ?? '').toString().toLowerCase() ==
              kode.toLowerCase(),
          orElse: () => null,
        );
        if (match != null) {
          setState(
            () => _namaApotekFound = match['nama_apotek'] ?? 'Apotek ditemukan',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Apotek ditemukan: $_namaApotekFound'),
                backgroundColor: AppColors.darkGreen,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Kode apotek tidak ditemukan.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cekLoading = false);
    }
  }


  Future<void> _handleRegister() async {
    final kode = _kodeApotekCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (kode.isEmpty ||
        name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Semua kolom harus diisi!')));
      return;
    }

    if (_namaApotekFound == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kode apotek belum diverifikasi. Tekan CEK terlebih dahulu.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.registerAdmin(
      name,
      email,
      password,
      phone,
      kode,
      _namaApotekFound!,
      kodeApotek: kode,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi Admin berhasil! Silakan login.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 100,
                left: 24,
                right: 24,
                bottom: 40,
              ),
              decoration: const BoxDecoration(
                color: AppColors.darkGreen,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Buat akun MedFast untuk mulai memesan\nobat.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kode Apotek',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16, right: 12),
                                child: Icon(
                                  Icons.vpn_key_outlined,
                                  color: Colors.black87,
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _kodeApotekCtrl,
                                  decoration: const InputDecoration(
                                    hintText: 'Kode Apotek',
                                    hintStyle: TextStyle(color: Colors.black45),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      _cekLoading
                          ? const SizedBox(
                              width: 44,
                              height: 44,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.darkGreen,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: _cekKodeApotek,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF94A9A0),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Text(
                                  'CEK',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),


                  if (_namaApotekFound != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.darkGreen,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _namaApotekFound!,
                          style: const TextStyle(
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 28),


                  const Text(
                    'Data Pemilik',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _inputField('Username', Icons.person_outline, _nameCtrl),
                  const SizedBox(height: 12),
                  _inputField(
                    'Email',
                    Icons.mail_outline,
                    _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    'Mobile Number',
                    Icons.call_outlined,
                    _phoneCtrl,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _inputField(
                    'Password',
                    Icons.lock_outline,
                    _passwordCtrl,
                    isPassword: true,
                  ),

                  const SizedBox(height: 36),


                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      onPressed: authProvider.isLoading
                          ? null
                          : _handleRegister,
                      child: authProvider.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),


                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Sudah punya akun? ',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.darkGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(icon, color: Colors.black87),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.black38,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 4,
          ),
        ),
      ),
    );
  }
}
