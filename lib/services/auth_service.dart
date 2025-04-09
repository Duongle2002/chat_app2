import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Phương thức để lắng nghe trạng thái xác thực
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // Đăng ký người dùng
  Future<void> signUp(String email, String password, {String? username}) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;
      if (user != null) {
        // Lấy FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) {
          print('Failed to get FCM token during sign up');
        }
        // Lưu thông tin người dùng vào Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'created_at': FieldValue.serverTimestamp(),
          'email': email,
          'id': user.uid,
          'is_active': true,
          'role': 'user',
          'user_id': user.uid,
          'username': username ?? email.split('@')[0],
          'fcm_token': fcmToken, // Lưu FCM token
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // Đăng nhập người dùng
  Future<void> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // Cập nhật FCM token sau khi đăng nhập
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('Failed to get FCM token during sign in');
      }
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).set(
          {'fcm_token': fcmToken},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      print('Error during sign in: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy thông tin người dùng hiện tại
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw Exception('User data not found in Firestore');
      }
      return doc.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  // Lấy UID của người dùng hiện tại
  String getCurrentUserId() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }
    return user.uid;
  }
}