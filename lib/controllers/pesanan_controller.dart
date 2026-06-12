import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_client.dart';
import '../services/auth_service.dart';

class PesananController extends ChangeNotifier {
  List<dynamic> orders = [];
  bool isLoading = true;
  IO.Socket? _socket;
  String? errorMessage;

  void initSocket(String? userId) {
    try {
      final rawUrl = ApiClient.baseUrl;
      final socketUrl = rawUrl.substring(0, rawUrl.lastIndexOf('/api'));

      debugPrint('Initializing Customer Order Socket with URL: \$socketUrl');

      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('Customer Order Socket connected successfully');
        if (userId != null) {
          debugPrint(
            'Customer Order Socket: Joining orders updates for user \$userId',
          );
          _socket!.emit('join_orders_updates', userId);
        }
      });

      _socket!.onConnectError((err) {
        debugPrint('Customer Order Socket connection error: \$err');
      });

      _socket!.onError((err) {
        debugPrint('Customer Order Socket error: \$err');
      });

      _socket!.on('order_status_updated', (data) {
        debugPrint('Order status updated event received: \$data');
        fetchOrders();
      });

      _socket!.onDisconnect((_) {
        debugPrint('Customer Order Socket disconnected');
      });
    } catch (e) {
      debugPrint('Error order socket init: \$e');
    }
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> fetchOrders() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/pesanan', token: token);
      if (response.statusCode == 200) {
        final List<dynamic> rawOrders = jsonDecode(response.body);
        
        // Fetch details in parallel to populate detail_pesanan
        final futures = rawOrders.map((o) async {
          final idPesanan = o['id_pesanan'];
          if (idPesanan != null) {
            try {
              final detailResponse = await ApiClient.get('/pesanan/$idPesanan', token: token);
              if (detailResponse.statusCode == 200) {
                return jsonDecode(detailResponse.body);
              }
            } catch (e) {
              debugPrint('Error fetching detail for order $idPesanan: $e');
            }
          }
          return o;
        }).toList();

        orders = await Future.wait(futures);
      } else {
        errorMessage = 'Gagal mengambil data pesanan';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> cancelOrder(int idPesanan) async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.put('/pesanan/$idPesanan', {
        'status_pesanan': 'dibatalkan',
      }, token: token);

      if (response.statusCode == 200) {
        fetchOrders();
        return true;
      } else {
        errorMessage =
            jsonDecode(response.body)['message'] ?? 'Gagal membatalkan pesanan';
        notifyListeners();
        return false;
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetail(int idPesanan) async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/pesanan/$idPesanan', token: token);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        errorMessage = 'Gagal mengambil detail pesanan';
        notifyListeners();
        return null;
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<int?> createChatRoom(int userId, int idAdmin, int idApotek) async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post('/chat/room', {
        'id_pelanggan': userId,
        'id_admin': idAdmin,
        'id_apotek': idApotek,
      }, token: token);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        final room = resData['data'];
        return room['id_chat'];
      } else {
        errorMessage = 'Gagal membuat room chat';
        notifyListeners();
        return null;
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
