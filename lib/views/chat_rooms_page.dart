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

  Widget _buildEmptyState() {
    return Center(
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
                backgroundColor: const Color(0xFF3F5E53),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    return Scaffold(
      backgroundColor: const Color(0xFFDFECE7),
      body: Stack(
        children: [
          const SizedBox.expand(),
          Container(
            height: 160,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF3F5E53),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Kotak Masuk Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _fetchRooms,
                ),
              ],
            ),
          ),
          Positioned(
            top: 130,
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F5E53)))
                    : _rooms.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _rooms.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.06),
                              indent: 20,
                              endIndent: 20,
                            ),
                            itemBuilder: (context, index) {
                              final room = _rooms[index];
                              final apotek = room['apotek'] ?? {};
                              final pelanggan = room['pelanggan'] ?? {};
                              
                              final isAdmin = user?.role == 'admin';
                              final displayName = isAdmin
                                  ? (pelanggan['nama'] ?? 'Pelanggan')
                                  : (apotek['nama_apotek'] ?? 'Apotek');
                              
                              final dateStr = _formatDate(room['tanggal_chat']);
                              final subtitleText = isAdmin
                                  ? 'Pertanyaan seputar produk atau pesanan'
                                  : 'Hubungi apotek untuk info produk atau pengiriman.';
                              
                              final lastMessage = room['pesan_terakhir'] ?? room['last_message'] ?? subtitleText;
                              final unreadCount = room['unread_count'] ?? room['unread'] ?? 0;

                              return InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatPage(
                                        chatId: room['id_chat'],
                                        roomName: displayName,
                                        idAdmin: room['id_admin'] ?? 0,
                                      ),
                                    ),
                                  ).then((_) => _fetchRooms());
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Color(0xFF1E3A2F),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              lastMessage,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 14,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.black38,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (unreadCount > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF3F5E53),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Text(
                                                '$unreadCount',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            )
                                          else
                                            const Icon(
                                              Icons.done_all,
                                              size: 16,
                                              color: Colors.black38,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ),
        ],
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
}
