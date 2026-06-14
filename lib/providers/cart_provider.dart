import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();

  List<dynamic> _cartItems = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;


  int get totalItems {
    int total = 0;
    for (var item in _cartItems) {
      total += (item['jumlah'] as num? ?? 0).toInt();
    }
    return total;
  }


  double get totalHarga {
    double total = 0;
    for (var item in _cartItems) {
      final qty = (item['jumlah'] as num? ?? 0).toDouble();
      final obat = item['obat'] as Map<String, dynamic>?;
      if (obat != null) {
        final price = (obat['harga'] ?? obat['price'] ?? 0) as num;
        total += qty * price.toDouble();
      }
    }
    return total;
  }


  Future<void> fetchCart() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      _cartItems = await _cartService.getCart();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> addToCart(int idObat, int quantity) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _cartService.addToCart(idObat, quantity);
      await fetchCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> updateQuantity(int idKeranjang, int quantity) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _cartService.updateQuantity(idKeranjang, quantity);
      await fetchCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> deleteItem(int idKeranjang) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _cartService.deleteItem(idKeranjang);
      await fetchCart();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> clearCart() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    try {
      await _cartService.clearCart();
      _cartItems = [];
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
