import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/strings.dart';
import '../../../core/services/auth_service.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _churchCodeController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Map<String, dynamic>? _churchData;

  @override
  void dispose() {
    _churchCodeController.dispose();
    super.dispose();
  }

  // ─── 교회 코드 Firestore 검증 ─────────────────────
  Future<void> _verifyChurchCode() async {
    final code = _churchCodeController.text.trim();

    if (code.isEmpty) {
      _showSnackBar('교회 코드를 입력해주세요');
      return;
    }
    if (code.length < 4) {
      _showSnackBar('교회 코드를 정확히 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = await _authService.verifyChurchCode(code);
      if (!mounted) return;

      if (data == null) {
        _showSnackBar('존재하지 않는 교회 코드입니다', isError: true);
        setState(() => _churchData = null);
      } else {
        setState(() => _churchData = data);
      }
    } catch (e) {
      if (mounted) _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── 이메일 로그인 화면으로 이동 ──────────────────
  void _goToEmailLogin() {
    if (_churchData == null) {
      _showSnackBar('먼저 교회 코드를 확인해주세요', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailLoginScreen(churchData: _churchData!),
      ),
    );
  }

  void _loginWithKakao() {
    if (_churchData == null) {
      _showSnackBar('먼저 교회 코드를 확인해주세요', isError: true);
      return;
    }
    _showSnackBar('카카오 로그인은 준비 중입니다');
  }

  void _goToSignUp() {
    if (_churchData == null) {
      _showSnackBar('먼저 교회 코드를 확인해주세요', isError: true);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmailLoginScreen(
          churchData: _churchData!,
          isSignUp: true,
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),

              // 로고
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 50,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                AppConfig.appName,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 48),

              // 교회 코드 입력
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '교회 코드',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _churchCodeController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: '교회 코드 입력 (예: 123456)',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (_) {
                            if (_churchData != null) {
                              setState(() => _churchData = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyChurchCode,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(80, 56),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('확인'),
                      ),
                    ],
                  ),

                  // 교회명 표시
                  if (_churchData != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _churchData!['name'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),

              // 이메일 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _goToEmailLogin,
                  icon: const Icon(Icons.email_outlined),
                  label: const Text('이메일로 로그인'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 카카오 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loginWithKakao,
                  icon: const Icon(Icons.chat_bubble),
                  label: const Text('카카오로 시작하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 회원가입 링크
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '아직 회원이 아니신가요?',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: _goToSignUp,
                    child: const Text(
                      '회원가입',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
