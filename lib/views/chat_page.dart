import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../controllers/chat_controller.dart';
import '../utils/colors.dart';

class ChatPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatController(),
      child: _ChatPageUI(
        chatId: chatId,
        roomName: roomName,
        idAdmin: idAdmin,
      ),
    );
  }
}

class _ChatPageUI extends StatefulWidget {
  final int chatId;
  final String roomName;
  final int idAdmin;

  const _ChatPageUI({
    required this.chatId,
    required this.roomName,
    required this.idAdmin,
  });

  @override
  State<_ChatPageUI> createState() => _ChatPageUIState();
}

class _ChatPageUIState extends State<_ChatPageUI> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final controller = context.read<ChatController>();
      controller.onMessagesUpdated = _scrollToBottom;
      controller.initSocket(widget.chatId);
      controller.loadMessages(widget.chatId);
      controller.markAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    // Tandai sudah dibaca sebelum keluar
    try {
      final controller = context.read<ChatController>();
      controller.markAsRead(widget.chatId);
      controller.disposeSocket();
    } catch (_) {}
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user == null) return;
    final myId = int.tryParse(user.uid);
    if (myId == null) return;

    _msgController.clear();
    final controller = context.read<ChatController>();

    controller.sendMessage(
      chatId: widget.chatId,
      text: text,
      myId: myId,
      userName: user.name,
      userRole: user.role,
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

  void _pickAndUploadImage(ImageSource source) {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final myId = int.tryParse(user?.uid ?? '');
    if (myId == null) return;

    final controller = context.read<ChatController>();
    controller.pickAndUploadImage(
      source: source,
      chatId: widget.chatId,
      myId: myId,
      userName: user?.name,
      userRole: user?.role,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    final controller = context.watch<ChatController>();

    if (controller.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(controller.errorMessage!), backgroundColor: Colors.redAccent),
        );
        controller.errorMessage = null; // reset
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3F5E53)))
                : controller.messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(controller, user),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  /// Header bar with room name and online status.
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF3F5E53),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.only(top: 40, left: 12, right: 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.roomName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFF50D199), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Online', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty state when there are no messages yet.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.chat_outlined, size: 70, color: Colors.black26),
          SizedBox(height: 12),
          Text('Mulai obrolan Anda sekarang', style: TextStyle(color: Colors.black45)),
        ],
      ),
    );
  }

  /// The scrollable list of chat messages.
  Widget _buildMessageList(ChatController controller, dynamic user) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: controller.messages.length,
      itemBuilder: (context, index) {
        final msg = controller.messages[index];
        final text = msg['pesan'] ?? '';
        final timeStr = controller.formatTime(msg['waktu_kirim']);

        final senderId = msg['id_pengirim']?.toString();
        final myId = user?.uid;
        final bool isOnRightSide = (senderId != null && myId != null && senderId == myId);

        bool showDayHeader = false;
        String dayHeaderText = '';
        if (index == 0) {
          showDayHeader = true;
          dayHeaderText = controller.getDayHeader(msg['waktu_kirim']);
        } else {
          final prevMsg = controller.messages[index - 1];
          final currentDay = controller.getDayHeader(msg['waktu_kirim']);
          final prevDay = controller.getDayHeader(prevMsg['waktu_kirim']);
          if (currentDay != prevDay) {
            showDayHeader = true;
            dayHeaderText = currentDay;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDayHeader && dayHeaderText.isNotEmpty)
              _buildDayHeader(dayHeaderText),
            _buildChatBubble(text, isOnRightSide, timeStr),
          ],
        );
      },
    );
  }

  /// Day separator header (e.g. "Hari Ini", "Kemarin").
  Widget _buildDayHeader(String text) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Individual chat bubble widget.
  Widget _buildChatBubble(String text, bool isOnRightSide, String time) {
    final controller = context.read<ChatController>();
    final bool isImage = controller.isImageUrl(text);

    return Align(
      alignment: isOnRightSide ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isOnRightSide ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isOnRightSide ? const Color(0xFF3F5E53) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isOnRightSide ? const Radius.circular(20) : const Radius.circular(0),
                  bottomRight: isOnRightSide ? const Radius.circular(0) : const Radius.circular(20),
                ),
                border: isOnRightSide ? null : Border.all(color: Colors.black.withOpacity(0.05), width: 1.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: isImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        text,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const SizedBox(width: 150, height: 150, child: Center(child: CircularProgressIndicator(color: Color(0xFF3F5E53))));
                        },
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(color: isOnRightSide ? Colors.white : const Color(0xFF1E3A2F), fontSize: 15, height: 1.4),
                    ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: isOnRightSide
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all, size: 14, color: Color(0xFF3F5E53)),
                      ],
                    )
                  : Text(time, style: const TextStyle(fontSize: 11, color: Colors.black38)),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom message input bar with image picker and send button.
  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black.withOpacity(0.08), width: 1.0),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined, color: Colors.black38, size: 24),
                      onPressed: () => _showImageSourceActionSheet(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        style: const TextStyle(fontSize: 15, color: Color(0xFF1E3A2F)),
                        decoration: const InputDecoration(
                          hintText: 'Tulis pesan...',
                          hintStyle: TextStyle(color: Colors.black26, fontSize: 15),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black.withOpacity(0.05), width: 1.0),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))
                  ],
                ),
                child: const Icon(Icons.send, color: Color(0xFF3F5E53), size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
