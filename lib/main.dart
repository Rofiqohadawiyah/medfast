import 'package:flutter/material.dart';
import 'register_page.dart';
import 'package:device_preview/device_preview.dart';

void main() {
  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => const MedFastApp(),
    ),
  );
}

class MedFastApp extends StatelessWidget {
  const MedFastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      title: 'MedFast',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        fontFamily: 'Arial',
        useMaterial3: true,
      ),
      home: const RegisterPage(),
    );
  }
}