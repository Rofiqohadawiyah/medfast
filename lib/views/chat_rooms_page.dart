import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../controllers/chat_rooms_controller.dart';
import 'chat_page.dart';
import 'apotek_page.dart';

class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatRoomsController(),
      child: const _ChatRoomsPageUI(),
    );
  }
}

class _ChatRoomsPageUI extends StatefulWidget {
  const _ChatRoomsPageUI();

  @override
  State<_ChatRoomsPageUI> createState() => _ChatRoomsPageUIState();
}

class _ChatRoomsPageUIState extends State<_ChatRoomsPageUI> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).userModel;
      if (user != null) {
        context.read<ChatRoomsController>().fetchRooms(user.uid);
      }
    });
  }

  void _refreshRooms() {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      context.read<ChatRoomsController>().fetchRooms(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userModel;
    final controller = context.watch<ChatRoomsController>();

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
                  onPressed: _refreshRooms,
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
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F5E53)))
                    : controller.rooms.isEmpty
                        ? _buildEmptyState(context)
                        : _buildRoomList(controller, user),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
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


  Widget _buildRoomList(ChatRoomsController controller, dynamic user) {
    final isAdmin = user?.role == 'admin';

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: controller.rooms.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.black.withOpacity(0.06),
        indent: 20,
        endIndent: 20,
      ),
      itemBuilder: (context, index) {
        final room = controller.rooms[index] as Map<String, dynamic>;
        final displayName = controller.getDisplayName(room, isAdmin);
        final lastMessage = controller.getLastMessage(room, isAdmin);
        final unreadCount = controller.getUnreadCount(room);


        final dateStr = controller.formatDate(
          room['pesan_terakhir_waktu']?.toString() ?? room['tanggal_chat']?.toString(),
        );

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
            ).then((_) => _refreshRooms());
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
                        style: TextStyle(
                          fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1E3A2F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          color: unreadCount > 0 ? Colors.black87 : Colors.black54,
                          fontSize: 14,
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
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
                      style: TextStyle(
                        fontSize: 11,
                        color: unreadCount > 0 ? const Color(0xFF25D366) : Colors.black38,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (unreadCount > 0)
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color(0xFF25D366),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
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
    );
  }
}
