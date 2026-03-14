import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드 - 실패해도 앱 계속 실행
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] .env 로드 실패: $e');
  }

  // Firebase 초기화
  await Firebase.initializeApp();

  // 푸시 알림 초기화 (백그라운드 핸들러는 최우선 등록)
  await NotificationService.initialize();

  runApp(const ChimshinBibleApp());
}
