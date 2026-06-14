import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'login_page.dart';
import 'register_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkGreen,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/LogoMedFast.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 50),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'MedFast',
                style: TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'Obat cepat, sehat dekat.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(flex: 3),

              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDFBFA),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                  },
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? ', style: TextStyle(fontSize: 16, color: Colors.white)),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 16, color: Color(0xFF4299E1), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
