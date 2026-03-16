import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] .env 로드 실패: $e');
  }

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('[main] Firebase 초기화 실패: $e');
  }

  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('[main] 알림 서비스 초기화 실패: $e');
  }

  runApp(const ChimshinBibleApp());
}
