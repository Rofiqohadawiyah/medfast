import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../services/api_client.dart';
import 'login_page.dart';
export 'register_admin_page.dart';

class RegisterPelangganPage extends StatefulWidget {
  const RegisterPelangganPage({super.key});

  @override
  State<RegisterPelangganPage> createState() => _RegisterPelangganPageState();
}

class _RegisterPelangganPageState extends State<RegisterPelangganPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom harus diisi!')),
      );
      return;
    }
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format email tidak valid.')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.register(name, email, password, phone, 'pelanggan');

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil! Silakan login.'), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.errorMessage)),
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
          children: [
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
                  Text('Register', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 12),
                  Text('Buat akun MedFast untuk mulai memesan obat.', style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _inputField('Username', Icons.person_outline, _nameCtrl),
                  const SizedBox(height: 20),
                  _inputField('Email', Icons.email_outlined, _emailCtrl),
                  const SizedBox(height: 20),
                  _inputField('Nomor HP', Icons.phone_outlined, _phoneCtrl),
                  const SizedBox(height: 20),
                  _inputField('Password', Icons.lock_outline, _passwordCtrl, isPassword: true),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Register', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? ', style: TextStyle(fontSize: 16, color: Colors.black54)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text('Login', style: TextStyle(fontSize: 16, color: AppColors.linkColor, fontWeight: FontWeight.bold)),
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

  Widget _inputField(String hint, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Padding(padding: const EdgeInsets.only(left: 20, right: 10), child: Icon(icon, color: Colors.black87)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.black54),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
