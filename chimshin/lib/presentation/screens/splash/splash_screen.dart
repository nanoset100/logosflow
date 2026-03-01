import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/services/auth_service.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // 최소 2초 스플래시 표시
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authService = AuthService();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // 로그인 상태 → 저장된 교회코드로 Firestore에서 교회 데이터 가져오기
      try {
        final churchCode = await authService.getSavedChurchCode();

        if (churchCode != null && churchCode.isNotEmpty) {
          final churchData = await authService.verifyChurchCode(churchCode);

          if (!mounted) return;

          if (churchData != null) {
            // 교회 데이터 정상 → 홈으로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(churchData: churchData),
              ),
            );
            return;
          }
        }
      } catch (_) {
        // Firestore 오류 또는 토큰 만료 → 로그인 화면으로
      }

      // 교회코드 없거나 조회 실패 → 로그아웃 후 로그인 화면으로 (온보딩 아님)
      await authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // 비로그인 상태 → 온보딩으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const OnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 120,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.appTagline,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator.adaptive(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
