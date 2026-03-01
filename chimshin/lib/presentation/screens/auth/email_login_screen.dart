import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/auth_service.dart';
import '../home/home_screen.dart';

class EmailLoginScreen extends StatefulWidget {
  final Map<String, dynamic> churchData;
  final bool isSignUp; // 회원가입 모드 여부

  const EmailLoginScreen({
    super.key,
    required this.churchData,
    this.isSignUp = false,
  });

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late bool _isSignUpMode;

  @override
  void initState() {
    super.initState();
    _isSignUpMode = widget.isSignUp;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  // ─── 로그인 ──────────────────────────────────────
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('이메일과 비밀번호를 입력해주세요', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (!mounted) return;
      if (user != null) {
        // 교회코드 저장 (로그인 유지용)
        final code = widget.churchData['code'] as String? ?? '';
        if (code.isNotEmpty) await _authService.saveChurchCode(code);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(churchData: widget.churchData),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── 회원가입 ─────────────────────────────────────
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _passwordConfirmController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnackBar('모든 항목을 입력해주세요', isError: true);
      return;
    }
    if (password != confirm) {
      _showSnackBar('비밀번호가 일치하지 않습니다', isError: true);
      return;
    }
    if (password.length < 6) {
      _showSnackBar('비밀번호는 6자 이상이어야 합니다', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final churchCode = widget.churchData['code'] as String? ??
          widget.churchData['id'] as String? ?? '';
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
        churchCode: churchCode,
      );
      if (!mounted) return;
      if (user != null) {
        // 교회코드 저장 (로그인 유지용)
        if (churchCode.isNotEmpty) await _authService.saveChurchCode(churchCode);
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(churchData: widget.churchData),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(e.toString().replaceAll('Exception: ', ''), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    final churchName = widget.churchData['name'] as String;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isSignUpMode ? '회원가입' : '이메일 로그인'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 교회명 표시
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.church, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      churchName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 이메일
              const Text(
                '이메일',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 비밀번호
              const Text(
                '비밀번호',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: _isSignUpMode
                    ? TextInputAction.next
                    : TextInputAction.done,
                onSubmitted: _isSignUpMode ? null : (_) => _login(),
                decoration: InputDecoration(
                  hintText: '비밀번호 (6자 이상)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textHint,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              // 비밀번호 확인 (회원가입 모드에서만 표시)
              if (_isSignUpMode) ...[
                const SizedBox(height: 20),
                const Text(
                  '비밀번호 확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordConfirmController,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _signUp(),
                  decoration: InputDecoration(
                    hintText: '비밀번호 재입력',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textHint,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // 로그인 / 회원가입 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : (_isSignUpMode ? _signUp : _login),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSignUpMode ? '회원가입' : '로그인',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // 로그인 ↔ 회원가입 전환
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isSignUpMode ? '이미 계정이 있으신가요?' : '아직 계정이 없으신가요?',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUpMode = !_isSignUpMode;
                        _passwordController.clear();
                        _passwordConfirmController.clear();
                      });
                    },
                    child: Text(
                      _isSignUpMode ? '로그인' : '회원가입',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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
