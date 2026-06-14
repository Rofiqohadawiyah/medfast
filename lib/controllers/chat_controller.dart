import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ChatController extends ChangeNotifier {
  final List<dynamic> messages = [];
  bool isLoading = true;
  IO.Socket? _socket;
  String? errorMessage;


  VoidCallback? onMessagesUpdated;


  bool isImageUrl(String text) {
    return text.startsWith('http') && (
      text.contains('.png') ||
      text.contains('.jpg') ||
      text.contains('.jpeg') ||
      text.contains('.webp') ||
      text.contains('.gif') ||
      text.contains('/storage/v1/object/public/') ||
      text.contains('chat_images')
    );
  }


  String formatTime(String? isoString) {
    if (isoString == null) return '';
    try {
      String cleanStr = isoString.trim();
      if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && !cleanStr.contains(RegExp(r'-\d{2}:\d{2}'))) {
        cleanStr = cleanStr.replaceAll(' ', 'T');
        cleanStr = '${cleanStr}Z';
      }
      final date = DateTime.parse(cleanStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }


  String getDayHeader(String? isoString) {
    if (isoString == null) return '';
    try {
      String cleanStr = isoString.trim();
      if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && !cleanStr.contains(RegExp(r'-\d{2}:\d{2}'))) {
        cleanStr = cleanStr.replaceAll(' ', 'T');
        cleanStr = '${cleanStr}Z';
      }
      final date = DateTime.parse(cleanStr).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final msgDay = DateTime(date.year, date.month, date.day);

      if (msgDay == today) {
        return 'Hari Ini';
      } else if (msgDay == yesterday) {
        return 'Kemarin';
      } else {
        final months = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (_) {
      return '';
    }
  }

  void initSocket(int chatId) {
    final rawUrl = ApiClient.baseUrl;
    final socketUrl = rawUrl.substring(0, rawUrl.lastIndexOf('/api'));

    _socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('Socket connected to server');
      _socket!.emit('join_room', chatId.toString());
    });

    _socket!.on('receive_message', (data) {
      final idMsg = data['id_message'] ?? data['id'];
      final index = messages.indexWhere(
        (m) =>
            ((m['id_message'] ?? m['id']) == idMsg) ||
            (m['id_message'] == null &&
                m['pesan'] == data['pesan'] &&
                m['id_pengirim']?.toString() ==
                    data['id_pengirim']?.toString()),
      );

      if (index != -1) {
        messages[index] = data;
      } else {
        messages.add(data);
      }

      markAsRead(chatId);
      notifyListeners();
      onMessagesUpdated?.call();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  void disposeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Future<void> markAsRead(int chatId) async {
    final prefs = await SharedPreferences.getInstance();



    String? latestMsgTime;
    if (messages.isNotEmpty) {

      latestMsgTime = messages.last['waktu_kirim']?.toString();
    }

    final timeToSave = latestMsgTime ?? DateTime.now().toUtc().toIso8601String();

    await prefs.setString('last_read_$chatId', timeToSave);
  }

  Future<void> loadMessages(int chatId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get(
        '/chat/messages/$chatId',
        token: token,
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> history = decoded['data'] ?? [];

        history.sort((a, b) {
          final tA = a['waktu_kirim']?.toString() ?? '';
          final tB = b['waktu_kirim']?.toString() ?? '';
          return tA.compareTo(tB);
        });

        messages.clear();
        messages.addAll(history);
        await markAsRead(chatId);
      } else {
        errorMessage = 'Gagal memuat riwayat chat';
      }
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
      onMessagesUpdated?.call();
    }
  }

  Future<void> sendMessage({
    required int chatId,
    required String text,
    required int myId,
    required String? userName,
    required String? userRole,
  }) async {
    if (text.isEmpty) return;

    final payload = {'id_chat': chatId, 'id_pengirim': myId, 'pesan': text};

    messages.add({
      'id_chat': chatId,
      'id_pengirim': myId,
      'pesan': text,
      'waktu_kirim': DateTime.now().toUtc().toIso8601String(),
      'pengirim': {'nama': userName, 'role': userRole},
    });

    notifyListeners();
    onMessagesUpdated?.call();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.post(
        '/chat/message',
        payload,
        token: token,
      );
      if (response.statusCode != 201) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Gagal mengirim pesan: $e';
      notifyListeners();
    }
  }

  Future<void> pickAndUploadImage({
    required ImageSource source,
    required int chatId,
    required int myId,
    required String? userName,
    required String? userRole,
  }) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile == null) return;

    isLoading = true;
    notifyListeners();

    try {
      final authService = AuthService();
      final token = await authService.token;

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/chat/upload'),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final bytes = await pickedFile.readAsBytes();
      final filename = pickedFile.name;
      final ext = filename.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : (ext == 'png' ? 'png' : ext);

      request.files.add(
        http.MultipartFile.fromBytes(
          'gambar',
          bytes,
          filename: filename,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final imageUrl = decoded['url'];

        if (imageUrl != null) {
          await sendMessage(
            chatId: chatId,
            text: imageUrl,
            myId: myId,
            userName: userName,
            userRole: userRole,
          );
        }
      } else {
        String serverError = 'Gagal mengunggah gambar ke server';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody != null && errBody['message'] != null) {
            serverError = errBody['message'];
          }
        } catch (_) {}
        errorMessage = serverError;
      }
    } catch (e) {
      errorMessage = 'Error upload: ${e.toString()}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
