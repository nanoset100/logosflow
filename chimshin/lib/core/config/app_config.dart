import 'package:flutter/material.dart';

class AppConfig {
  // 앱 정보
  static const String appName = '침신 말씀노트';
  static const String appNameEn = 'Chimshin Bible Note';
  static const String denomination = '침례교';
  static const int pricePerPerson = 250; // 원

  // 색상
  static const Color primaryColor = Color(0xFF4A90E2);
  static const Color secondaryColor = Color(0xFF7ED321);
  static const Color accentColor = Color(0xFFF5A623);
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color textColor = Color(0xFF333333);

  // Firebase
  static const String firebaseProjectId = 'chimshin-bible-note';

  // 버전
  static const String version = '1.0.0';
  static const int buildNumber = 1;
}
