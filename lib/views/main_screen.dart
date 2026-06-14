import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'admin_main_screen.dart';
import 'landing_page.dart';
import 'profile_page.dart';
import 'chat_rooms_page.dart';
import 'pesanan_page.dart';
import '../utils/colors.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user?.role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminMainScreen()),
        );
      }
    });
  }

  final List<Widget> _pages = [
    const LandingPage(),
    const ChatRoomsPage(),
    const PesananPage(),
    const ProfilePage(),
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
              onTap: (index) => setState(() => _selectedIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.darkGreen,
              unselectedItemColor: Colors.black38,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.medical_services, size: 28), label: 'Obat'),
                BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline, size: 28), label: 'Chat'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_bag, size: 28), label: 'Pesanan'),
                BottomNavigationBarItem(icon: Icon(Icons.person, size: 28), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
