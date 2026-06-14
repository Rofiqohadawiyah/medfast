

import 'dart:html' as html;
import 'package:flutter/material.dart';

void openPaymentUrl(String url) {
  html.window.open(url, '_blank');
}


class NativePaymentWebview extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Tidak tersedia di web')),
    );
  }
}
