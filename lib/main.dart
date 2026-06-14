import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'views/welcome_page.dart';
import 'views/main_screen.dart';
import 'views/admin_main_screen.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(const MedFastApp());
}

class MedFastApp extends StatelessWidget {
  const MedFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MedFast',
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFE2ECE4),
          fontFamily: 'Arial',
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<bool> _loginStatusFuture;

  @override
  void initState() {
    super.initState();
    _loginStatusFuture = Provider.of<AuthProvider>(context, listen: false)
        .checkLoginStatus()
        .whenComplete(() => FlutterNativeSplash.remove());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loginStatusFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final isLoggedIn = snapshot.data ?? false;
        if (isLoggedIn) {
          final user = Provider.of<AuthProvider>(context, listen: false).userModel;
          if (user?.role == 'admin') {
            return const AdminMainScreen();
          }
          return const MainScreen();
        }

        return const WelcomePage();
      },
    );
  }
}
