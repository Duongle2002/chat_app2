import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FCMService _fcmService = FCMService();

  // Lấy ID người dùng hiện tại
  String getCurrentUserId() {
    return _auth.currentUser!.uid;
  }

  // Lấy danh sách người dùng
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((doc) {
        final userData = doc.data();
        return userData['user_id'] != _auth.currentUser!.uid;
      })
          .map((doc) => doc.data())
          .toList();
      print('Fetched users: $users');
      return users;
    });
  }

  // Gửi tin nhắn và thông báo
  Future<void> sendMessage(String receiverId, String message) async {
    String senderId = _auth.currentUser!.uid;
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
    });

    // Lấy thông tin người nhận (bao gồm FCM token)
    DocumentSnapshot receiverDoc = await _firestore.collection('users').doc(receiverId).get();
    if (!receiverDoc.exists) {
      print('Receiver document not found for ID: $receiverId');
      return;
    }

    Map<String, dynamic>? receiverData = receiverDoc.data() as Map<String, dynamic>?;
    if (receiverData == null) {
      print('Receiver data is null for ID: $receiverId');
      return;
    }

    if (receiverData['fcm_token'] != null) {
      String receiverToken = receiverData['fcm_token'];
      String senderUsername = receiverData['username'] ?? _auth.currentUser!.email!.split('@')[0];
      print('Sending notification to token: $receiverToken');

      // Gửi thông báo qua FCM API V1
      await _fcmService.sendNotification(
        receiverToken,
        "New Message from $senderUsername",
        message,
      );
    } else {
      print('Receiver FCM token not found for ID: $receiverId');
    }
  }

  // Lấy tin nhắn
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
}