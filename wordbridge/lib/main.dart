import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'data/services/notification_service.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('[main] .env 로드 실패: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('[main] Firebase 초기화 성공');
    } catch (e) {
      debugPrint('[main] Firebase 초기화 실패: $e');
      // 사용자친화적 에러 화면 (기술적 모명 노출 안함)
      runApp(const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '네트워크 연결을 확인해 주세요',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    '앱을 시작하려면 인터넷 연결이 필요합니다.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
      return;
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
