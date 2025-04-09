import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../components/chat_bubble.dart';

class ChatPage extends StatelessWidget {
  final Map<String, dynamic> otherUser;
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();

  ChatPage({super.key, required this.otherUser});

  @override
  Widget build(BuildContext context) {
    String currentUserId = _chatService.getCurrentUserId();
    String otherUserId = otherUser['user_id'];

    // Đánh dấu tin nhắn là đã đọc khi mở trang chat
    _chatService.markMessagesAsRead(currentUserId, otherUserId);

    return Scaffold(
      appBar: AppBar(
        title: Text(otherUser['username'] ?? otherUser['email'] ?? 'Chat'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessages(currentUserId, otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet"));
                }
                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    bool isMe = message['senderId'] == currentUserId; // Đổi tên biến cho rõ nghĩa
                    return ChatBubble(
                      message: message['message'],
                      isMe: isMe, // Sử dụng isMe thay vì isSender
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: "Enter your message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () { // Sử dụng onPressed thay vì onTap
                    if (_messageController.text.isNotEmpty) {
                      _chatService.sendMessage(otherUserId, _messageController.text);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}