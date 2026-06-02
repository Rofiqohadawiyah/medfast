import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../utils/colors.dart';
import 'chat_page.dart';
import 'apotek_page.dart';

class ChatRoomsPage extends StatefulWidget {
  const ChatRoomsPage({super.key});

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  List<dynamic> _rooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    try {
      final authService = AuthService();
      final token = await authService.token;

      final response = await ApiClient.get('/chat/rooms/${user.uid}', token: token);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> rooms = decoded['data'] ?? [];
        if (mounted) {
          setState(() {
            _rooms = rooms;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat daftar obrolan');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text(
          'Kotak Masuk Chat',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        backgroundColor: AppColors.darkGreen,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchRooms,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.darkGreen))
          : _rooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 80, color: Colors.black26),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada obrolan aktif',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Anda bisa menghubungi apotek terdekat dari peta untuk berkonsultasi mengenai obat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black38, height: 1.4),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkGreen,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ApotekPage()),
                            );
                          },
                          icon: const Icon(Icons.map_outlined, color: Colors.white),
                          label: const Text('Buka Peta Apotek', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final room = _rooms[index];
                    final apotek = room['apotek'] ?? {};
                    final apotekName = apotek['nama_apotek'] ?? 'Apotek';
                    final firstLetter = apotekName.isNotEmpty ? apotekName[0].toUpperCase() : 'A';
                    final dateStr = _formatDate(room['tanggal_chat']);

                    return Card(
                      elevation: 1.5,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.lightGreen,
                          child: Text(
                            firstLetter,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkGreen, fontSize: 20),
                          ),
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                apotekName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              dateStr,
                              style: const TextStyle(fontSize: 11, color: Colors.black38),
                            ),
                          ],
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Hubungi apotek untuk info produk atau pengiriman.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black45, fontSize: 13),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatPage(
                                chatId: room['id_chat'],
                                roomName: apotekName,
                                idAdmin: room['id_admin'],
                              ),
                            ),
                          ).then((_) => _fetchRooms());
                        },
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      String cleanStr = isoString.trim();
      if (!cleanStr.endsWith('Z') && !cleanStr.contains('+') && !cleanStr.contains(RegExp(r'-\d{2}:\d{2}'))) {
        cleanStr = cleanStr.replaceAll(' ', 'T');
        cleanStr = '${cleanStr}Z';
      }
      final date = DateTime.parse(cleanStr).toLocal();
      return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
