import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  // Đường dẫn đến file service-account.json
  static const String _serviceAccountPath = 'lib/config/service-account.json';

  // Hàm lấy Access Token
  Future<String> getAccessToken() async {
    try {
      // Đọc file service-account.json
      final String serviceAccountJson = await rootBundle.loadString(_serviceAccountPath);
      if (serviceAccountJson.isEmpty) {
        throw Exception('Service account file is empty');
      }
      final Map<String, dynamic> serviceAccount = jsonDecode(serviceAccountJson);

      // Tạo credentials từ Service Account
      final credentials = ServiceAccountCredentials.fromJson(serviceAccount);
      const scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Lấy Access Token
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;
      client.close();
      return accessToken;
    } catch (e) {
      print('Error loading service account: $e');
      rethrow;
    }
  }

  // Hàm gửi thông báo qua FCM API V1
  Future<void> sendNotification(String token, String title, String body) async {
    try {
      final accessToken = await getAccessToken();
      const projectId = 'reactjs032025'; // Thay bằng Project ID từ Firebase Console
      final fcmUrl = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final Map<String, dynamic> message = {
        'message': {
          'token': token,
          'notification': {
            'title': title,
            'body': body,
          },
          'android': {
            'priority': 'high',
          },
          'apns': {
            'headers': {
              'apns-priority': '10',
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully: ${response.body}');
      } else {
        print('Failed to send notification: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}