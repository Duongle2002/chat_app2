import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        // Lưu thông tin người dùng vào Firestore với cấu trúc giống dữ liệu hiện có
        await _firestore.collection('users').doc(user.uid).set({
          'created_at': FieldValue.serverTimestamp(), // Lưu thời gian tạo (sẽ tự động chuyển thành ISO 8601 string)
          'email': email,
          'id': user.uid, // id giống user_id
          'is_active': true,
          'role': 'user',
          'user_id': user.uid, // user_id giống uid từ Firebase Auth
          'username': username ?? email.split('@')[0], // Nếu không có username, dùng phần trước @ của email
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // Đăng nhập người dùng
  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}