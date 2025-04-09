import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService(); // Thêm FCMService

  // Lấy danh sách người dùng
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    });
  }

  // Lấy UID của người dùng hiện tại
  String getCurrentUserId() {
    return _authService.getCurrentUserId();
  }

  // Lấy tin nhắn giữa hai người dùng
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String receiverId, String message) async {
    String senderId = getCurrentUserId();
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

    // Lưu tin nhắn vào Firestore
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    // Lấy thông tin người gửi
    DocumentSnapshot senderDoc = await _firestore.collection('users').doc(senderId).get();
    if (!senderDoc.exists) {
      print('Sender not found');
      return;
    }
    final senderData = senderDoc.data() as Map<String, dynamic>;
    final senderName = senderData['username'] ?? senderData['email'];

    // Lấy fcm_token của người nhận
    DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) {
      print('Receiver not found');
      return;
    }
    final receiverData = receiverDoc.data() as Map<String, dynamic>;
    final fcmToken = receiverData['fcm_token'];

    if (fcmToken == null) {
      print('No FCM token for receiver');
      return;
    }

    // Gửi thông báo
    await _fcmService.sendNotification(
      fcmToken,
      'New message from $senderName',
      message,
    );
  }

  // Đánh dấu tin nhắn là đã đọc
  Future<void> markMessagesAsRead(String userId, String otherUserId) async {
    try {
      List<String> ids = [userId, otherUserId];
      ids.sort();
      String chatRoomId = ids.join("_");
      print('Marking messages as read - ChatRoomId: $chatRoomId, UserId: $userId, OtherUserId: $otherUserId');

      QuerySnapshot unreadMessages = await _firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('senderId', isEqualTo: otherUserId)
          .where('isRead', isEqualTo: false)
          .get();

      print('Found ${unreadMessages.docs.length} unread messages');

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'isRead': true});
        print('Updated isRead for message: ${doc.id}');
      }
    } catch (e) {
      print('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Lấy số tin nhắn chưa đọc
  Stream<int> getUnreadMessagesCount(String userId, String otherUserId) {
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join("_");
    print('Fetching unread messages - ChatRoomId: $chatRoomId, UserId: $userId, OtherUserId: $otherUserId');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('senderId', isEqualTo: otherUserId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      print('Unread messages count: ${snapshot.docs.length}');
      return snapshot.docs.length;
    });
  }
}