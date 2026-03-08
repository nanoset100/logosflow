import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드 (OpenAI API 키 등) - 실패해도 앱 계속 실행
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[main] .env 로드 실패: $e');
  }

  // Firebase 초기화
  await Firebase.initializeApp();

  runApp(
    const ProviderScope(
      child: ChimshinBibleApp(),
    ),
  );
}
