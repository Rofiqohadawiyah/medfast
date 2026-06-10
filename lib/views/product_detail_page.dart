import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'alamat_saya_page.dart';
import 'main_screen.dart';
import 'apotek_detail_page.dart';
import '../services/payment_service.dart';
import 'payment_webview_page.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isLoadingApotek = true;
  int? _idApotek;
  String _namaApotek = 'Apotek Mitra';
  String _alamatApotek = 'Detail alamat apotek...';
  String _jamOperasional = '08.00 - 21.00';
  double? _apotekLat;
  double? _apotekLng;

  double _distanceInKm = 2.5; // Fallback distance (2.5 km -> Rp 10.000)
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _fetchApotekInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchApotekInfo() async {
    final targetId = widget.product['id_obat'] ?? widget.product['id'];
    
    // 1. Fetch all detailed apoteks first
    List<dynamic> allApoteks = [];
    try {
      final response = await ApiClient.get('/apotek');
      if (response.statusCode == 200) {
        allApoteks = jsonDecode(response.body);
      }
    } catch (_) {}

    // 2. Try to get apotek from stock list and match detailed data
    try {
      final response = await ApiClient.get('/stok-obat');
      if (response.statusCode == 200) {
        final List<dynamic> stockList = jsonDecode(response.body);
        final match = stockList.firstWhere(
          (item) => item['id_obat']?.toString() == targetId?.toString(),
          orElse: () => null,
        );
        if (match != null && match['id_apotek'] != null) {
          final detailedApotek = allApoteks.firstWhere(
            (a) => a['id_apotek']?.toString() == match['id_apotek']?.toString(),
            orElse: () => null,
          );
          if (detailedApotek != null) {
            if (mounted) {
              setState(() {
                _idApotek = detailedApotek['id_apotek'];
                _namaApotek = detailedApotek['nama_apotek'] ?? 'Apotek Mitra';
                _alamatApotek = detailedApotek['alamat'] ?? 'Detail alamat apotek...';
                _jamOperasional = detailedApotek['jam_operasional'] ?? '08.00 - 21.00';
                _apotekLat = (detailedApotek['latitude'] as num?)?.toDouble();
                _apotekLng = (detailedApotek['longitude'] as num?)?.toDouble();
                _isLoadingApotek = false;
              });
              _triggerDistanceCalculation();
            }
            return;
          }
        }
      }
    } catch (_) {}

    // 3. Fallback: Get first apotek in system
    if (allApoteks.isNotEmpty) {
      final apotek = allApoteks[0];
      if (mounted) {
        setState(() {
          _idApotek = apotek['id_apotek'];
          _namaApotek = apotek['nama_apotek'] ?? 'Apotek Mitra';
          _alamatApotek = apotek['alamat'] ?? 'Detail alamat apotek...';
          _jamOperasional = apotek['jam_operasional'] ?? '08.00 - 21.00';
          _apotekLat = (apotek['latitude'] as num?)?.toDouble();
          _apotekLng = (apotek['longitude'] as num?)?.toDouble();
          _isLoadingApotek = false;
        });
        _triggerDistanceCalculation();
      }
      return;
    }

    if (mounted) {
      setState(() {
        _idApotek = 1;
        _isLoadingApotek = false;
      });
    }
  }

  void _triggerDistanceCalculation() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final address = user?.alamat ?? '';
    _calculateDistance(address);
  }

  bool _isApotekOpen(dynamic jamOperasional) {
    if (jamOperasional == null) return false;
    final String jamStr = jamOperasional.toString();
    if (jamStr.isEmpty || jamStr == '-') return false;
    try {
      final parts = jamStr.split('-');
      if (parts.length != 2) return false;
      
      final startStr = parts[0].trim().replaceAll('.', ':');
      final endStr = parts[1].trim().replaceAll('.', ':');
      
      final startParts = startStr.split(':');
      final endParts = endStr.split(':');
      if (startParts.length < 2 || endParts.length < 2) return false;
      
      final startHour = int.parse(startParts[0]);
      final startMin = int.parse(startParts[1]);
      
      final endHour = int.parse(endParts[0]);
      final endMin = int.parse(endParts[1]);
      
      final now = DateTime.now();
      final nowHour = now.hour;
      final nowMin = now.minute;
      
      final startMinutes = startHour * 60 + startMin;
      final endMinutes = endHour * 60 + endMin;
      final nowMinutes = nowHour * 60 + nowMin;
      
      if (startMinutes <= endMinutes) {
        return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
      } else {
        return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
      }
    } catch (_) {
      return false;
    }
  }

  Future<void> _calculateDistance(String address) async {
    if (_apotekLat == null || _apotekLng == null) return;
    setState(() => _isCalculatingDistance = true);

    double? userLat;
    double? userLng;

    // 1. Try GPS First (requesting permission if denied)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
          );
          userLat = pos.latitude;
          userLng = pos.longitude;
        }
      }
    } catch (_) {}

    // 2. Geocode address string using Nominatim if GPS failed
    if ((userLat == null || userLng == null) && address.isNotEmpty) {
      try {
        final searchUrl = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(address)}&limit=1',
        );
        final searchRes = await http.get(searchUrl, headers: {'User-Agent': 'MedFastApp/1.0'});
        if (searchRes.statusCode == 200) {
          final list = jsonDecode(searchRes.body) as List;
          if (list.isNotEmpty) {
            userLat = double.parse(list[0]['lat']);
            userLng = double.parse(list[0]['lon']);
          }
        }
      } catch (_) {}
    }

    // 3. Calculate final distance
    if (userLat != null && userLng != null && _apotekLat != null && _apotekLng != null) {
      final distanceInMeters = Geolocator.distanceBetween(
        _apotekLat!,
        _apotekLng!,
        userLat,
        userLng,
      );
      if (mounted) {
        setState(() {
          _distanceInKm = distanceInMeters / 1000.0;
          _isCalculatingDistance = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isCalculatingDistance = false);
      }
    }
  }

  Future<void> _tambahKeKeranjang() async {
    final idObat = widget.product['id_obat'] ?? widget.product['id'];
    if (idObat == null) return;

    final idObatInt = int.tryParse(idObat.toString()) ?? 0;
    if (idObatInt == 0) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.darkGreen),
      ),
    );

    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final success = await cartProvider.addToCart(idObatInt, 1);

      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Obat berhasil dimasukkan ke keranjang!'),
              backgroundColor: AppColors.darkGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menambah ke keranjang: ${cartProvider.errorMessage}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.product['harga'] ?? widget.product['price'] ?? 0;
    final imageUrl = widget.product['gambar'] ?? widget.product['imageUrl'] ?? 'https://via.placeholder.com/300';
    final name = widget.product['nama_obat'] ?? widget.product['name'] ?? 'Nama Obat';
    final desc = widget.product['deskripsi'] ?? widget.product['description'] ?? 'Belum ada deskripsi untuk produk ini.';

    // Listen to AuthProvider address changes to recalculate distance
    Provider.of<AuthProvider>(context).userModel;

    final stockVal = widget.product['jumlah_stok'] ?? widget.product['stock'];
    final stock = stockVal != null ? (int.tryParse(stockVal.toString()) ?? 0) : null;
    final isOutOfStock = stock != null && stock <= 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar Obat & Back Button
              Stack(
                children: [
                  Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 320,
                      color: const Color(0xFFEFEFEF),
                      child: const Icon(Icons.medication, size: 100, color: Colors.grey),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),

              // Product Info Block
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp $price',
                      style: const TextStyle(fontSize: 26, color: AppColors.darkGreen, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.darkGreen),
                          ),
                          child: const Text(
                            'Pilihan Terbaik',
                            style: TextStyle(color: AppColors.darkGreen, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Garansi 100% Asli',
                          style: TextStyle(color: Colors.black45, fontSize: 12),
                        ),
                        const Spacer(),
                        if (stock != null)
                          Text(
                            'Stok: $stock',
                            style: const TextStyle(
                              color: Color(0xFFEE4D2D), // Shopee Orange style
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Description Block
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deskripsi Produk',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      desc,
                      style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Apotek Profile Card (tappable -> ApotekDetailPage)
              GestureDetector(
                onTap: _isLoadingApotek
                    ? null
                    : () {
                        // Build a minimal apotek map from fetched data
                        final apotekData = <String, dynamic>{
                          'id_apotek': _idApotek,
                          'nama_apotek': _namaApotek,
                          'alamat': _alamatApotek,
                          'jam_operasional': _jamOperasional,
                          'latitude': _apotekLat,
                          'longitude': _apotekLng,
                        };
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ApotekDetailPage(apotek: apotekData),
                          ),
                        );
                      },
                child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: _isLoadingApotek
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: CircularProgressIndicator(color: AppColors.darkGreen),
                        ),
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: AppColors.lightGreen,
                            child: const Icon(
                              Icons.store,
                              color: AppColors.darkGreen,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _namaApotek,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Status Buka/Tutup Badge
                                    (() {
                                      final isOpen = _isApotekOpen(_jamOperasional);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isOpen
                                              ? const Color(0xFFE8F5E9)
                                              : const Color(0xFFEEEEEE),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isOpen
                                                ? const Color(0xFF81C784)
                                                : const Color(0xFFBDBDBD),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isOpen
                                                    ? const Color(0xFF4CAF50)
                                                    : const Color(0xFF9E9E9E),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isOpen ? 'Buka' : 'Tutup',
                                              style: TextStyle(
                                                color: isOpen
                                                    ? const Color(0xFF2E7D32)
                                                    : const Color(0xFF616161),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })(),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _alamatApotek,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                                 const SizedBox(height: 8),
                                 Row(
                                   children: [
                                     const Icon(Icons.location_on, size: 16, color: AppColors.darkGreen),
                                     const SizedBox(width: 4),
                                     _isCalculatingDistance
                                         ? const SizedBox(
                                             width: 12, height: 12,
                                             child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.darkGreen),
                                           )
                                         : Text(
                                             '${_distanceInKm.toStringAsFixed(1)} km dari lokasi Anda',
                                             style: const TextStyle(
                                               fontSize: 14,
                                               fontWeight: FontWeight.w600,
                                               color: AppColors.darkGreen,
                                             ),
                                           ),
                                   ],
                                 ),
                              ],
                            ),
                          ),
                        ],
                      ),
                ),
              ), // closes GestureDetector

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          child: Row(
            children: [
              // Chat icon
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.darkGreen),
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: AppColors.darkGreen),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                      (route) => false,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Tambah ke Keranjang Button (Icon)
              Container(
                decoration: BoxDecoration(
                  color: _isLoadingApotek || isOutOfStock ? Colors.grey[200] : AppColors.lightGreen,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _isLoadingApotek || isOutOfStock ? Colors.grey : AppColors.darkGreen),
                ),
                child: IconButton(
                  icon: Icon(Icons.add_shopping_cart, color: _isLoadingApotek || isOutOfStock ? Colors.grey : AppColors.darkGreen),
                  onPressed: (_isLoadingApotek || isOutOfStock) ? null : _tambahKeKeranjang,
                ),
              ),
              const SizedBox(width: 12),
              // Buy Now Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? Colors.grey : AppColors.darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    onPressed: (_isLoadingApotek || isOutOfStock)
                        ? null
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => _CheckoutSheet(
                                product: widget.product,
                                idApotek: _idApotek!,
                                namaApotek: _namaApotek,
                                distanceInKm: _distanceInKm,
                              ),
                            );
                          },
                    child: Text(
                      isOutOfStock ? 'Stok Habis' : 'Beli Sekarang',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSheet extends StatefulWidget {
  final Map<String, dynamic> product;
  final int idApotek;
  final String namaApotek;
  final double distanceInKm;

  const _CheckoutSheet({
    required this.product,
    required this.idApotek,
    required this.namaApotek,
    required this.distanceInKm,
  });

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  int _quantity = 1;
  String _paymentMethod = 'COD';
  bool _isSubmitting = false;
  bool _useCoins = false;

  Future<void> _submitCheckout(String address, int shippingFee) async {
    setState(() => _isSubmitting = true);

    final price = widget.product['harga'] ?? widget.product['price'] ?? 0;
    final coinDiscount = _useCoins ? 1000 : 0;
    final totalHarga = (price * _quantity) + shippingFee - coinDiscount;
    final idObat = widget.product['id_obat'] ?? widget.product['id'];

    try {
      final authService = AuthService();
      final token = await authService.token;

      // 1. Create order
      final pesananRes = await ApiClient.post(
        '/pesanan',
        {
          'id_apotek': widget.idApotek,
          'total_harga': totalHarga,
          'status_pesanan': 'menunggu',
          'detail_items': [
            {
              'id_obat': idObat,
              'jumlah': _quantity,
              'harga_satuan': price,
            }
          ]
        },
        token: token,
      );

      if (pesananRes.statusCode == 201) {
        final pesananData = jsonDecode(pesananRes.body);
        final idPesanan = pesananData['pesanan']['id_pesanan'];

        // 2. Create payment
        await ApiClient.post(
          '/pembayaran',
          {
            'id_pesanan': idPesanan,
            'metode_pembayaran': _paymentMethod,
            'status_pembayaran': 'belum_bayar',
          },
          token: token,
        );

        // 3. Create delivery
        await ApiClient.post(
          '/pengiriman',
          {
            'id_pesanan': idPesanan,
            'alamat_tujuan': address,
            'status_pengiriman': 'pending',
          },
          token: token,
        );

        if (mounted) {
          if (_paymentMethod == 'Midtrans') {
            final paymentService = PaymentService();
            final snapData = await paymentService.getSnapToken(idPesanan);

            if (mounted) {
              if (snapData != null && snapData['payment_url'] != null) {
                // Close modal and push webview
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentWebviewPage(
                      paymentUrl: snapData['payment_url'],
                      idPesanan: idPesanan,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan dibuat! Silakan bayar dari halaman Pesanan.'),
                    backgroundColor: AppColors.darkGreen,
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
                  (route) => false,
                );
              }
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pesanan berhasil dibuat!'), backgroundColor: AppColors.darkGreen),
            );
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2)),
              (route) => false,
            );
          }
        }
      } else {
        final errorMsg = jsonDecode(pesananRes.body)['message'] ?? 'Gagal membuat pesanan';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final address = user?.alamat ?? '';
    final hasAddress = address.trim().isNotEmpty;

    final price = widget.product['harga'] ?? widget.product['price'] ?? 0;
    final name = widget.product['nama_obat'] ?? widget.product['name'] ?? 'Nama Obat';
    final productSubtotal = price * _quantity;
    
    // Ongkir calculation based on Rp 4.000 per 1 km
    final shippingFee = (widget.distanceInKm * 4000).round();
    final coinDiscount = _useCoins ? 1000 : 0;
    final grandTotal = productSubtotal + shippingFee - coinDiscount;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Konfirmasi Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.black45),
                )
              ],
            ),
          ),

          // Scrollable details list
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Alamat Pengiriman
                  Container(
                    color: Colors.white,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.location_on, color: AppColors.darkGreen, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Alamat Pengiriman',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (!hasAddress) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lightGreen.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.darkGreen.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Expanded(
                                  child: Text(
                                    'Alamat belum diatur! Anda wajib mengatur alamat pengiriman terlebih dahulu.',
                                    style: TextStyle(color: AppColors.darkGreen, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.darkGreen,
                                    side: const BorderSide(color: AppColors.darkGreen),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AlamatSayaPage()));
                                  },
                                  child: const Text('Atur', style: TextStyle(fontSize: 12)),
                                )
                              ],
                            ),
                          ),
                        ] else ...[
                          Text(
                            user?.name ?? 'Nama Pelanggan',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            address,
                            style: const TextStyle(color: Colors.black54, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 2. Rincian Toko & Produk
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pharmacy name
                        Row(
                          children: [
                            const Icon(Icons.store, color: Colors.black54, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              widget.namaApotek,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(color: AppColors.darkGreen, borderRadius: BorderRadius.circular(4)),
                              child: const Text('Mitra', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Product Card
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: widget.product['gambar'] != null
                                  ? Image.network(widget.product['gambar'], fit: BoxFit.cover)
                                  : const Icon(Icons.medication, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Rp $price',
                                    style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity Controls
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(2)),
                                    ),
                                    child: const Icon(Icons.remove, size: 14, color: Colors.black54),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    border: Border.symmetric(vertical: BorderSide(color: Colors.grey[300]!)),
                                  ),
                                  child: Text('$_quantity', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() => _quantity++),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
                                    ),
                                    child: const Icon(Icons.add, size: 14, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 3. Opsi Pengiriman (Ongkir dinamis)
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Opsi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(
                              'Reguler (Rp $shippingFee)',
                              style: const TextStyle(color: AppColors.darkGreen, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Estimasi tiba dalam 1 - 2 jam',
                              style: TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                            Text(
                              'Jarak: ${widget.distanceInKm.toStringAsFixed(1)} km (Rp 4.000 / km)',
                              style: const TextStyle(color: Colors.black45, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 4. Koin MedFast
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text('Tukarkan 1.000 Koin MedFast', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        Switch(
                          value: _useCoins,
                          activeThumbImage: null, // Fixed activeThumbImage deprecated parameter warnings
                          activeColor: AppColors.darkGreen,
                          onChanged: (val) => setState(() => _useCoins = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 5. Metode Pembayaran
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _paymentMethod = 'COD'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _paymentMethod == 'COD' ? AppColors.lightGreen.withOpacity(0.4) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _paymentMethod == 'COD' ? AppColors.darkGreen : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Text(
                                  'COD (Bayar di Tempat)',
                                  style: TextStyle(
                                    color: _paymentMethod == 'COD' ? AppColors.darkGreen : Colors.black87,
                                    fontWeight: _paymentMethod == 'COD' ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),

                            GestureDetector(
                              onTap: () => setState(() => _paymentMethod = 'Midtrans'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _paymentMethod == 'Midtrans' ? const Color(0xFFDFECE7) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.payment, size: 14, color: _paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.black87),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Bayar Online',
                                      style: TextStyle(
                                        color: _paymentMethod == 'Midtrans' ? AppColors.darkGreen : Colors.black87,
                                        fontWeight: _paymentMethod == 'Midtrans' ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 6. Rincian Pembayaran Breakdown
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rincian Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal untuk Produk', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            Text('Rp $productSubtotal', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal Pengiriman', style: TextStyle(color: Colors.black54, fontSize: 13)),
                            Text('Rp $shippingFee', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                        if (_useCoins) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('Diskon Koin MedFast', style: TextStyle(color: Colors.black54, fontSize: 13)),
                              Text('-Rp 1.000', style: TextStyle(color: AppColors.darkGreen, fontSize: 13)),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            Text(
                              'Rp $grandTotal',
                              style: const TextStyle(color: AppColors.darkGreen, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(color: Colors.black54, fontSize: 11)),
                        Text(
                          'Rp $grandTotal',
                          style: const TextStyle(color: AppColors.darkGreen, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 46,
                    width: 160,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.darkGreen,
                        disabledBackgroundColor: Colors.grey[300],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: (!hasAddress || _isSubmitting)
                          ? null
                          : () => _submitCheckout(address, shippingFee),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Buat Pesanan',
                              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
