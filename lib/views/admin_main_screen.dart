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
      backgroundColor: AppColors.lightGreen,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.darkGreen,
              unselectedItemColor: Colors.black38,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Beranda'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded, size: 28), label: 'Pesanan'),
                BottomNavigationBarItem(icon: Icon(Icons.medication_rounded, size: 28), label: 'Produk'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

