import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app2/pages/login_page.dart';
import 'package:chat_app2/pages/register_page.dart';
import 'package:chat_app2/pages/home_page.dart';
import 'package:chat_app2/pages/chat_page.dart';
import 'package:chat_app2/pages/settings_page.dart';
import 'package:chat_app2/orgate/auth_gate.dart';

// Hàm xử lý thông báo khi ứng dụng ở trạng thái background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background message received: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Khởi tạo Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Yêu cầu quyền thông báo (Android 13+)
    FirebaseMessaging.instance.requestPermission();

    // Lắng nghe thông báo khi ứng dụng ở foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Foreground message received: ${message.notification?.title}");
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "${message.notification!.title}: ${message.notification!.body}",
            ),
          ),
        );
      }
    });

    // Lắng nghe khi người dùng nhấn vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.data}");
    });

    // Lắng nghe khi FCM token thay đổi
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("FCM Token refreshed: $newToken");
      // Cập nhật token mới vào Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'fcm_token': newToken},
          SetOptions(merge: true),
        );
      }
    });

    // Lấy token FCM ban đầu
    _getFCMToken();
  }

  Future<void> _getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Token: $token");
    // Lưu token vào Firestore nếu người dùng đã đăng nhập
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcm_token': token},
        SetOptions(merge: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: Colors.blue,
          secondary: Colors.blueAccent,
          background: Colors.grey[200],
        ),
      ),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => AuthGate(),
        '/login': (context) =>  LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) =>  HomePage(),
        '/chat': (context) => ChatPage(
          otherUser: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
        ),
        '/settings': (context) =>  SettingsPage(),
      },
    );
  }
}