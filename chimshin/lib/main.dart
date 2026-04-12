import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[main] Firebase 초기화 실패: $e');
  }

  // 푸시 알림 초기화 (백그라운드 핸들러는 최우선 등록)
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('[main] 알림 서비스 초기화 실패: $e');
  }

  runApp(const ChimshinBibleApp());
}
