import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'daily_wordnote_main';
  static const _channelName = '데일리 말씀노트 알림';

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 알림 권한 요청
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');

    // flutter_local_notifications 초기화
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 알림 채널 생성
    const channel = AndroidNotificationChannel(
      _channelId, _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // FCM 포그라운드 메시지 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] 포그라운드: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // 토픽 구독
    await _messaging.subscribeToTopic('daily_devotion');
    debugPrint('[FCM] daily_devotion 토픽 구독 완료');

    await saveToken();
    _messaging.onTokenRefresh.listen((_) => saveToken());

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] 알림 탭: ${message.data}');
    });
  }

  /// iOS 전용: APNS 토큰이 준비될 때까지 최대 5초간 대기합니다. (심사 대응용)
  static Future<String?> _waitForApnsToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return null;
    
    debugPrint('[FCM] APNS 토큰 대기 시작...');
    for (int i = 0; i < 10; i++) { // 0.5초 * 10 = 5초
      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken != null) {
        debugPrint('[FCM] APNS 토큰 획득 성공');
        return apnsToken;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
    debugPrint('[FCM] APNS 토큰 획득 실패 (5초 타임아웃)');
    return null;
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF1A6B3A),
          playSound: true,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  static Future<void> saveToken() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      // iOS인 경우 APNS 토큰이 준비될 때까지 잠시 대기 (심사관 빠른 로그인 대응)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _waitForApnsToken();
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('[FCM] FCM 토큰이 null입니다. 저장을 건너튑니다.');
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token, 'tokenUpdatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
      debugPrint('[FCM] 토큰 저장 완료: ${token.substring(0, 20)}...');
    } catch (e) {
      // 심사 통과를 위해 기술적인 에러가 로그인을 방해하지 않도록 push 에러는 무시합니다.
      debugPrint('[FCM] 토큰 저장 중 무시된 에러: $e');
    }
  }

  static Future<void> onLogout(String uid) async {
    await _messaging.deleteToken();
    await _messaging.unsubscribeFromTopic('daily_devotion');
    await FirebaseFirestore.instance
        .collection('users').doc(uid)
        .update({'fcmToken': FieldValue.delete()});
    debugPrint('[FCM] 로그아웃 - 토큰 삭제 완료');
  }
}
