import 'package:flutter/material.dart';

class AppConfig {
  // 앱 정보
  static const String appName = '데일리 말씀노트';
  static const String appNameEn = 'Daily WordNote';
  static const String denomination = '';
  static const int pricePerPerson = 250; // 원

  // 색상
  static const Color primaryColor = Color(0xFF1A2B5E);
  static const Color secondaryColor = Color(0xFFC9960C);
  static const Color accentColor = Color(0xFFE8B832);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textColor = Color(0xFF333333);

  // Firebase
  static const String firebaseProjectId = 'daily-wordnote';

  // 서버 URL (공개 가능 - 서버 측에서 Firebase Auth 토큰으로 인증)
  static const String serverUrl = 'https://logosflow-production.up.railway.app';

  // 버전
  static const String version = '1.0.0';
  static const int buildNumber = 1;
}
