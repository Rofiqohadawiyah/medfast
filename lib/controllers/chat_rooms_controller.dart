import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ChatRoomsController extends ChangeNotifier {
  List<dynamic> rooms = [];
  bool isLoading = true;
  String? errorMessage;
  IO.Socket? _socket;
  String? _currentUserId;


  DateTime? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      String s = raw.trim();

      if (!s.contains('T')) {
        s = s.replaceFirst(' ', 'T');
      }
      if (!s.endsWith('Z') && !s.contains('+') && !RegExp(r'-\d{2}:\d{2}$').hasMatch(s)) {
        s = '${s}Z';
      }
      return DateTime.parse(s).toUtc();
    } catch (_) {
      return null;
    }
  }


  Future<void> fetchRooms(String userId, {bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/chat/rooms/$userId', token: token);
      if (response.statusCode != 200) {
        errorMessage = 'Gagal memuat daftar obrolan';
        isLoading = false;
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body);
      final List<dynamic> fetchedRooms = decoded['data'] ?? [];

      final prefs = await SharedPreferences.getInstance();
      final myIdStr = userId.toString();


      for (var room in fetchedRooms) {
        final chatId = room['id_chat'];
        if (chatId == null) continue;

        try {
          final msgRes = await ApiClient.get('/chat/messages/$chatId', token: token);
          if (msgRes.statusCode == 200) {
            final msgDecoded = jsonDecode(msgRes.body);
            final List<dynamic> msgs = msgDecoded['data'] ?? [];

            if (msgs.isNotEmpty) {

              msgs.sort((a, b) {
                final tA = _parseTime(a['waktu_kirim']?.toString());
                final tB = _parseTime(b['waktu_kirim']?.toString());
                if (tA == null && tB == null) return 0;
                if (tA == null) return -1;
                if (tB == null) return 1;
                return tA.compareTo(tB);
              });

              final lastMsg = msgs.last;
              String text = lastMsg['pesan']?.toString() ?? '';
              if (_isImageUrl(text)) {
                text = '📷 Gambar';
              }
              room['pesan_terakhir'] = text;
              room['pesan_terakhir_waktu'] = lastMsg['waktu_kirim'];

              final lastReadStr = prefs.getString('last_read_$chatId');
              final lastReadTime = _parseTime(lastReadStr);

              int unreadCount = 0;
              for (var msg in msgs) {
                final senderId = msg['id_pengirim']?.toString();
                if (senderId == myIdStr) continue;

                if (lastReadTime == null) {
                  unreadCount++;
                } else {
                  final msgTime = _parseTime(msg['waktu_kirim']?.toString());
                  if (msgTime != null && msgTime.isAfter(lastReadTime)) {
                    unreadCount++;
                  }
                }
              }
              room['unread_count'] = unreadCount;
            }
          }
        } catch (_) {}
      }


      fetchedRooms.sort((a, b) {
        final tA = _parseTime(a['pesan_terakhir_waktu']?.toString() ?? a['tanggal_chat']?.toString() ?? a['updated_at']?.toString());
        final tB = _parseTime(b['pesan_terakhir_waktu']?.toString() ?? b['tanggal_chat']?.toString() ?? b['updated_at']?.toString());
        if (tA == null && tB == null) return 0;
        if (tA == null) return 1;
        if (tB == null) return -1;
        return tB.compareTo(tA);
      });

      rooms = fetchedRooms;


      if (_socket == null) {
        _initSocket(userId, fetchedRooms);
      } else {

        for (var r in fetchedRooms) {
          final cid = r['id_chat'];
          if (cid != null) {
            _socket!.emit('join_room', cid.toString());
          }
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      debugPrint('[ChatRooms] fetchRooms error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _initSocket(String userId, List<dynamic> fetchedRooms) {
    _socket = IO.io(ApiClient.baseUrl.replaceFirst('/api', ''), <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('[ChatRooms] Socket connected');
      for (var r in fetchedRooms) {
        final cid = r['id_chat'];
        if (cid != null) {
          _socket!.emit('join_room', cid.toString());
        }
      }
    });

    _socket!.on('receive_message', (data) {
      debugPrint('[ChatRooms] New message received: $data');

      fetchRooms(userId, showLoading: false);
    });

    _socket!.onDisconnect((_) => debugPrint('[ChatRooms] Socket disconnected'));
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }


  bool _isImageUrl(String text) {
    return text.startsWith('http') && (
      text.contains('.png') ||
      text.contains('.jpg') ||
      text.contains('.jpeg') ||
      text.contains('object/public/')
    );
  }


  String formatDate(String? isoString) {
    final dt = _parseTime(isoString);
    if (dt == null) return '';
    try {
      final date = dt.toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDay = DateTime(date.year, date.month, date.day);

      if (msgDay == today) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (msgDay == yesterday) {
        return 'Kemarin';
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
          'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
        ];
        return '${date.day} ${months[date.month - 1]}';
      }
    } catch (_) {
      return '';
    }
  }


  String getDisplayName(Map<String, dynamic> room, bool isAdmin) {
    final apotek = room['apotek'] ?? {};
    final pelanggan = room['pelanggan'] ?? {};
    return isAdmin
        ? (pelanggan['nama'] ?? 'Pelanggan')
        : (apotek['nama_apotek'] ?? 'Apotek');
  }


  String getSubtitleText(bool isAdmin) {
    return isAdmin
        ? 'Pertanyaan seputar produk atau pesanan'
        : 'Hubungi apotek untuk info produk atau pengiriman.';
  }


  String getLastMessage(Map<String, dynamic> room, bool isAdmin) {
    return room['pesan_terakhir'] ?? room['last_message'] ?? getSubtitleText(isAdmin);
  }


  int getUnreadCount(Map<String, dynamic> room) {
    return room['unread_count'] ?? room['unread'] ?? 0;
  }
}
