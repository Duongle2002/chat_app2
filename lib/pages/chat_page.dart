import 'package:flutter/material.dart';
import '../components/my_text_field.dart';
import '../components/chat_bubble.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final Map<String, dynamic> otherUser;

  const ChatPage({required this.otherUser});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      final receiverId = widget.otherUser['user_id'];
      if (receiverId != null) {
        _chatService.sendMessage(receiverId, _messageController.text);
        _messageController.clear();
        _scrollToBottom();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Receiver ID is null")),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _chatService.getCurrentUserId();

    // Kiểm tra dữ liệu đầu vào
    if (widget.otherUser['user_id'] == null) {
      print('Invalid user data in ChatPage: ${widget.otherUser}');
      return const Scaffold(
        body: Center(child: Text('Invalid user data: User ID is missing')),
      );
    }

    String displayName = widget.otherUser['username']?.isNotEmpty == true
        ? widget.otherUser['username']
        : widget.otherUser['email'] ?? 'Unknown User';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _chatService.getMessages(currentUserId, widget.otherUser['user_id']),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!.docs;
                _scrollToBottom();
                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    return ChatBubble(
                      message: msg['message'] ?? 'No message',
                      isMe: msg['senderId'] == currentUserId,
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
                  child: MyTextField(
                    controller: _messageController,
                    hintText: "Type a message",
                    obscureText: false,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}