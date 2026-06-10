import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'admin_beranda_page.dart';
import 'admin_pesanan_page.dart';
import 'admin_produk_page.dart';
import 'admin_profil_page.dart';

class AdminMainScreen extends StatefulWidget {
  final int initialIndex;
  const AdminMainScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminMainScreen> createState() => AdminMainScreenState();
}

class AdminMainScreenState extends State<AdminMainScreen> {
  late int _selectedIndex;

  void setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> _pages = const [
    AdminBerandaPage(),
    AdminPesananPage(),
    AdminProdukPage(),
    AdminProfilPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2EEE9),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
                _buildNavItem(1, Icons.assignment_outlined, Icons.assignment_rounded, 'Pesanan'),
                _buildNavItem(2, Icons.inventory_2_outlined, Icons.inventory_2_rounded, 'Produk'),
                _buildNavItem(3, Icons.person_outline, Icons.person_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5F5ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? const Color(0xFF1E3A2F) : Colors.black54,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black87 : Colors.black38,
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

