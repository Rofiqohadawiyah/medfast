// Native (Android/iOS) implementation - uses webview_flutter
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void openPaymentUrl(String url) {
  // No-op on native, WebView handles it
}

class NativePaymentWebview extends StatefulWidget {
  final String paymentUrl;
  final int idPesanan;
  final VoidCallback? onSuccess;
  final VoidCallback? onFailure;

  const NativePaymentWebview({
    super.key,
    required this.paymentUrl,
    required this.idPesanan,
    this.onSuccess,
    this.onFailure,
  });

  @override
  State<NativePaymentWebview> createState() => _NativePaymentWebviewState();
}

class _NativePaymentWebviewState extends State<NativePaymentWebview> {
  late final WebViewController _controller;
  bool _isLoading = true;

  static const _successKeywords = [
    'status_code=200',
    'transaction_status=settlement',
    'transaction_status=capture',
    'finish',
    'success',
  ];

  static const _failureKeywords = [
    'status_code=202',
    'transaction_status=deny',
    'transaction_status=expire',
    'transaction_status=cancel',
    'error',
    'failure',
  ];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            _checkPaymentStatus(url);
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            _checkPaymentStatus(url);
          },
          onWebResourceError: (error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final lowerUrl = url.toLowerCase();

    final isSuccess = _successKeywords.any((kw) => lowerUrl.contains(kw));
    final isFailure = _failureKeywords.any((kw) => lowerUrl.contains(kw));

    if (isSuccess) {
      _showResultDialog(success: true);
    } else if (isFailure) {
      _showResultDialog(success: false);
    }
  }

  void _showResultDialog({required bool success}) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              success ? Icons.check_circle : Icons.cancel,
              color: success ? const Color(0xFF3F5E53) : Colors.redAccent,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              success ? 'Pembayaran Berhasil!' : 'Pembayaran Gagal',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              success
                  ? 'Pesanan kamu sedang diproses oleh apotek.'
                  : 'Silakan coba lagi atau gunakan metode pembayaran lain.',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: success ? const Color(0xFF3F5E53) : Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // close webview
                if (success) {
                  widget.onSuccess?.call();
                } else {
                  widget.onFailure?.call();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  success ? 'Lihat Pesanan' : 'Kembali',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
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
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Batalkan Pembayaran?'),
                        content: const Text('Apakah kamu yakin ingin meninggalkan halaman ini?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tidak'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              Navigator.pop(context);
                            },
                            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.redAccent)),
                          ),
                        ],
                      ),
                    );
                  },
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
          if (_isLoading)
            const LinearProgressIndicator(
              color: Color(0xFF3F5E53),
              backgroundColor: Color(0xFFDFECE7),
            ),
          Expanded(
            child: WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
