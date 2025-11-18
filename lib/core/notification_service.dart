import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Xin quyền nhận thông báo (Android sẽ auto chấp nhận, iOS hiện popup)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Đăng ký topic chung cho các thông báo về review
    await messaging.subscribeToTopic('reviews');

    // In token ra log để bạn test nếu muốn gửi theo token
    final token = await messaging.getToken();
    debugPrint('FCM token: $token');
  }
}
