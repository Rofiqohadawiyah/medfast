import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'main_screen.dart';

// Conditional imports
import 'payment_webview_native.dart' if (dart.library.html) 'payment_webview_web.dart' as payment_impl;

class PaymentWebviewPage extends StatelessWidget {
  final String paymentUrl;
  final int idPesanan;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const PaymentWebviewPage({
    super.key,
    required this.paymentUrl,
    required this.idPesanan,
    this.onSuccess,
    this.onFailure,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, open URL in new tab and show waiting page
      return _WebPaymentPage(
        paymentUrl: paymentUrl,
        idPesanan: idPesanan,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    } else {
      // On mobile, use the native WebView
      return payment_impl.NativePaymentWebview(
        paymentUrl: paymentUrl,
        idPesanan: idPesanan,
        onSuccess: onSuccess,
        onFailure: onFailure,
      );
    }
  }
}

/// Web-specific payment page that opens Midtrans in a new tab
class _WebPaymentPage extends StatefulWidget {
  final String paymentUrl;
  final int idPesanan;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const _WebPaymentPage({
    required this.paymentUrl,
    required this.idPesanan,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<_WebPaymentPage> createState() => _WebPaymentPageState();
}

class _WebPaymentPageState extends State<_WebPaymentPage> {
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    // Open payment URL in new tab after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPaymentUrl();
    });
  }

  void _openPaymentUrl() {
    if (!_opened) {
      _opened = true;
      payment_impl.openPaymentUrl(widget.paymentUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xFF3F5E53),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(top: 44, left: 12, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pembayaran',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Powered by Midtrans',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.open_in_new,
                      size: 64,
                      color: Color(0xFF3F5E53),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Halaman pembayaran sudah dibuka\ndi tab baru browser-mu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3F5E53),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Silakan selesaikan pembayaran di tab tersebut.\nSetelah selesai, klik tombol di bawah.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    // Button to re-open payment URL
                    OutlinedButton.icon(
                      onPressed: () => payment_impl.openPaymentUrl(widget.paymentUrl),
                      icon: const Icon(Icons.refresh, color: Color(0xFF3F5E53)),
                      label: const Text(
                        'Buka Ulang Halaman Pembayaran',
                        style: TextStyle(color: Color(0xFF3F5E53)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF3F5E53)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Button to go to orders
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F5E53),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Sudah Bayar? Lihat Pesanan',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
