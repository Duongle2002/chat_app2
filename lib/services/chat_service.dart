import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy ID người dùng hiện tại
  String getCurrentUserId() {
    return _auth.currentUser!.uid;
  }

  // Lấy danh sách người dùng
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) {
        // So sánh user_id trong dữ liệu với uid của người dùng hiện tại
        final userData = doc.data();
        return userData['user_id'] != _auth.currentUser!.uid;
      })
          .map((doc) => doc.data())
          .toList();
    });
  }

  // Gửi tin nhắn
  Future<void> sendMessage(String receiverId, String message) async {
    String senderId = _auth.currentUser!.uid;
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join("_");

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