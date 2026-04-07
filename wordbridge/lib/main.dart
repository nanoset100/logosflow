import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
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

    // 🔍 디버그: Flutter 위젯 크래시 시 회색 화면 대신 에러 텍스트 표시
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Crash Log', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              'ERROR: ${details.exceptionAsString()}\n\n'
              'STACK TRACE:\n${details.stack}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    };

    runApp(const WordBridgeApp());
  }, (error, stack) {
    debugPrint('[main] Uncaught error: $error\n$stack');
  });
}
