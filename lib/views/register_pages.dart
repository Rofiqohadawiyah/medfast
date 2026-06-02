import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/colors.dart';
import '../services/api_client.dart';
import 'login_page.dart';

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

// ─── Admin Register Page ─────────────────────────────────────────────────────
class RegisterAdminPage extends StatefulWidget {
  const RegisterAdminPage({super.key});

  @override
  State<RegisterAdminPage> createState() => _RegisterAdminPageState();
}

class _RegisterAdminPageState extends State<RegisterAdminPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _pharmacyCodeCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isCheckingCode = false;
  Map<String, dynamic>? _foundPharmacy;
  String? _foundPharmacyId;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _pharmacyCodeCtrl.dispose();
    super.dispose();
  }

  // Cari apotek berdasarkan kode unik
  Future<void> _checkPharmacyCode() async {
    final code = _pharmacyCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _isCheckingCode = true; _foundPharmacy = null; });

    try {
      final response = await ApiClient.get('/apotek');
      if (response.statusCode == 200) {
        final List<dynamic> apoteks = jsonDecode(response.body);
        final found = apoteks.firstWhere(
          (a) => a['kode_apotek']?.toString().toUpperCase() == code,
          orElse: () => null,
        );

        if (found != null) {
          setState(() {
            _foundPharmacy = found;
            _foundPharmacyId = found['id_apotek']?.toString() ?? found['id']?.toString();
            _isCheckingCode = false;
          });
        } else {
          setState(() { _foundPharmacy = null; _foundPharmacyId = null; _isCheckingCode = false; });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kode apotek tidak ditemukan. Periksa kembali kode kamu.'), backgroundColor: Colors.red),
            );
          }
        }
      } else {
        throw Exception("Gagal memuat data apotek");
      }
    } catch (e) {
      setState(() => _isCheckingCode = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleRegister() async {
    if (_foundPharmacy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan dan verifikasi kode apotek terlebih dahulu!')),
      );
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom harus diisi!')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.registerAdmin(
      name, email, password, phone, _foundPharmacyId!, _foundPharmacy!['name'] ?? '',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi admin berhasil! Silakan login.'), backgroundColor: Colors.green),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(authProvider.errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF1A2B22),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, left: 32, right: 32, bottom: 50),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1F17),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50), bottomRight: Radius.circular(50)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: const Text('ADMIN PORTAL', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Daftar Admin', style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Masukkan kode apotek untuk memulai.', style: TextStyle(fontSize: 15, color: Colors.white60)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Input Kode Apotek ───
                  const Text('Kode Apotek', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: const Color(0xFF253328), borderRadius: BorderRadius.circular(16)),
                          child: TextField(
                            controller: _pharmacyCodeCtrl,
                            style: const TextStyle(color: Colors.white, letterSpacing: 2, fontWeight: FontWeight.bold),
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: APT-JBR-001',
                              hintStyle: TextStyle(color: Colors.white38),
                              prefixIcon: Icon(Icons.qr_code, color: Colors.greenAccent),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        ),
                        onPressed: _isCheckingCode ? null : _checkPharmacyCode,
                        child: _isCheckingCode
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Cek', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  // ─── Hasil Apotek Ditemukan ───
                  if (_foundPharmacy != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_foundPharmacy!['nama_apotek'] ?? _foundPharmacy!['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(_foundPharmacy!['alamat'] ?? _foundPharmacy!['address'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  const Text('Data Pemilik', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _darkField('Nama Lengkap', Icons.person_outline, _nameCtrl),
                  const SizedBox(height: 14),
                  _darkField('Email', Icons.email_outlined, _emailCtrl),
                  const SizedBox(height: 14),
                  _darkField('Nomor HP', Icons.phone_outlined, _phoneCtrl),
                  const SizedBox(height: 14),
                  _darkField('Password', Icons.lock_outline, _passwordCtrl, isPassword: true),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.black,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: authProvider.isLoading ? null : _handleRegister,
                      child: authProvider.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Daftar Sekarang', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun? ', style: TextStyle(color: Colors.white54)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                        child: const Text('Login', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
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

  Widget _darkField(String hint, IconData icon, TextEditingController ctrl, {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF253328), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword && _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.white54),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
