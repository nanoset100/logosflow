import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');

    await _messaging.subscribeToTopic('daily_devotion');
    debugPrint('[FCM] daily_devotion 토픽 구독 완료');

    await saveToken();
    _messaging.onTokenRefresh.listen((_) => saveToken());

    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] 포그라운드: ${message.notification?.title} - ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] 알림 탭: ${message.data}');
    });
  }

  static Future<void> saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).set(
      {
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    debugPrint('[FCM] 토큰 저장 완료: ${token.substring(0, 20)}...');
  }

  static Future<void> onLogout(String uid) async {
    await _messaging.deleteToken();
    await _messaging.unsubscribeFromTopic('daily_devotion');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'fcmToken': FieldValue.delete()});
    debugPrint('[FCM] 로그아웃 - 토큰 삭제 완료');
  }
}
