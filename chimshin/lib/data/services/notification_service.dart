import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// FCM 백그라운드 메시지 핸들러 (앱 완전 종료 시)
/// @pragma 필수 - tree-shaking에서 제거되지 않도록
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background: ${message.notification?.title}');
}

class NotificationService {
  static final _messaging = FirebaseMessaging.instance;

  /// 앱 시작 시 한 번 호출 (Firebase.initializeApp() 이후)
  static Future<void> initialize() async {
    // 백그라운드 핸들러 등록 (최우선 등록)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 알림 권한 요청 (iOS/Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] 권한 상태: ${settings.authorizationStatus}');

    // 매일 오전 묵상 알림 주제 구독
    await _messaging.subscribeToTopic('daily_devotion');
    debugPrint('[FCM] daily_devotion 토픽 구독 완료');

    // 로그인 상태이면 토큰 저장
    await saveToken();

    // 토큰 갱신 시 자동 재저장
    _messaging.onTokenRefresh.listen((_) => saveToken());

    // 포그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] 포그라운드: ${message.notification?.title} - ${message.notification?.body}');
    });

    // 알림 탭으로 앱 열릴 때
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] 알림 탭: ${message.data}');
    });
  }

  /// FCM 토큰을 Firestore users/{uid}에 저장
  /// 로그인 후 호출하여 개인 푸시 알림에 활용
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

  /// 로그아웃 시 토큰 삭제 및 토픽 구독 해제
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
