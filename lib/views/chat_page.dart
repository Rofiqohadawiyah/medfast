import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';

class ChatPage extends StatefulWidget {
  final int chatId;
  final String roomName;
  final int idAdmin;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.roomName,
    required this.idAdmin,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<dynamic> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  IO.Socket? _socket;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initSocket();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initSocket() {
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
      _socket!.emit('join_room', widget.chatId.toString());
    });

    _socket!.on('receive_message', (data) {
      if (mounted) {
        setState(() {
          final idMsg = data['id_message'] ?? data['id'];
          // Find if there is an existing match or matching optimistic message
          final index = _messages.indexWhere((m) =>
              ((m['id_message'] ?? m['id']) == idMsg) ||
              (m['id_message'] == null &&
                  m['pesan'] == data['pesan'] &&
                  m['id_pengirim']?.toString() == data['id_pengirim']?.toString()));
          if (index != -1) {
            // Replace optimistic message with actual server message
            _messages[index] = data;
          } else {
            _messages.add(data);
          }
        });
        _scrollToBottom();
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });
  }

  Future<void> _loadMessages() async {
    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/chat/messages/${widget.chatId}', token: token);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> history = decoded['data'] ?? [];
        if (mounted) {
          setState(() {
            _messages.clear();
            _messages.addAll(history);
            _isLoading = false;
          });
          _scrollToBottom();
        }
      } else {
        throw Exception('Gagal memuat riwayat chat');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;

    final myId = int.tryParse(user.uid);
    if (myId == null) return;

    _msgController.clear();

    final payload = {
      'id_chat': widget.chatId,
      'id_pengirim': myId,
      'pesan': text,
    };

    // Optimistic UI update
    setState(() {
      _messages.add({
        'id_chat': widget.chatId,
        'id_pengirim': myId,
        'pesan': text,
        'waktu_kirim': DateTime.now().toUtc().toIso8601String(),
        'pengirim': {
          'nama': user.name,
          'role': user.role,
        }
      });
    });
    _scrollToBottom();

    // Kirim pesan lewat HTTP POST agar terjamin masuk database Supabase
    try {
      final authService = AuthService();
      final token = await authService.token;
      
      final response = await ApiClient.post('/chat/message', payload, token: token);
      if (response.statusCode != 201) {
        throw Exception('Server mengembalikan status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal mengirim pesan ke server: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  bool _isImageUrl(String text) {
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

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.darkGreen),
                title: const Text('Kamera (Ambil Foto)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.darkGreen),
                title: const Text('Galeri (Pilih dari Penyimpanan)'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final myId = int.tryParse(user?.uid ?? '');
    if (myId == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _isLoading = true);

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

      final ext = pickedFile.path.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'jpg' || ext == 'jpeg') ? 'jpeg' : ext;

      request.files.add(
        await http.MultipartFile.fromPath(
          'gambar',
          pickedFile.path,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final imageUrl = decoded['url'];

        if (imageUrl != null) {
          final payload = {
            'id_chat': widget.chatId,
            'id_pengirim': myId,
            'pesan': imageUrl,
          };

          _socket?.emit('send_message', payload);

          setState(() {
            _messages.add({
              'id_chat': widget.chatId,
              'id_pengirim': myId,
              'pesan': imageUrl,
              'waktu_kirim': DateTime.now().toUtc().toIso8601String(),
              'pengirim': {
                'nama': user?.name,
                'role': user?.role,
              }
            });
          });
          _scrollToBottom();
        }
      } else {
        String serverError = 'Gagal mengunggah gambar ke server';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody != null && errBody['message'] != null) {
            serverError = errBody['message'];
          }
        } catch (_) {}
        throw Exception(serverError);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error upload: ${e.toString()}'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final myIdStr = user?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.roomName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppColors.darkGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.chat_outlined, size: 70, color: Colors.black26),
                            SizedBox(height: 12),
                            Text('Mulai obrolan Anda sekarang', style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final text = msg['pesan'] ?? '';
                          final timeStr = _formatTime(msg['waktu_kirim']);

                          final pengirimMap = msg['pengirim'] as Map<String, dynamic>?;
                          final senderRole = pengirimMap?['role']?.toString().toLowerCase() ?? 'pelanggan';
                          
                          // Tentukan sisi balon chat: kanan (hijau) atau kiri (putih)
                          final myRole = user?.role?.toLowerCase() ?? 'pelanggan';
                          bool isOnRightSide = false;
                          if (myRole == 'admin') {
                            isOnRightSide = (senderRole == 'admin');
                          } else {
                            isOnRightSide = (senderRole == 'pelanggan');
                          }

                          // Tentukan apakah harus menampilkan header tanggal (per hari)
                          bool showDayHeader = false;
                          String dayHeaderText = '';
                          if (index == 0) {
                            showDayHeader = true;
                            dayHeaderText = _getDayHeader(msg['waktu_kirim']);
                          } else {
                            final prevMsg = _messages[index - 1];
                            final currentDay = _getDayHeader(msg['waktu_kirim']);
                            final prevDay = _getDayHeader(prevMsg['waktu_kirim']);
                            if (currentDay != prevDay) {
                              showDayHeader = true;
                              dayHeaderText = currentDay;
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (showDayHeader && dayHeaderText.isNotEmpty)
                                Center(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 12),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      dayHeaderText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              _buildChatBubble(text, isOnRightSide, timeStr),
                            ],
                          );
                        },
                      ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: AppColors.darkGreen),
                    onPressed: () => _showImageSourceActionSheet(context),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F5F8),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.darkGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
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

  Widget _buildChatBubble(String text, bool isOnRightSide, String time) {
    return Align(
      alignment: isOnRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isOnRightSide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 2),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isOnRightSide ? AppColors.darkGreen : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isOnRightSide ? const Radius.circular(20) : const Radius.circular(0),
                bottomRight: isOnRightSide ? const Radius.circular(0) : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: _isImageUrl(text)
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      text,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 150,
                          height: 150,
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.darkGreen),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: isOnRightSide ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Text(
              time,
              style: const TextStyle(fontSize: 10, color: Colors.black38),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? isoString) {
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

  String _getDayHeader(String? isoString) {
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
        return 'Hari ini';
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
}
