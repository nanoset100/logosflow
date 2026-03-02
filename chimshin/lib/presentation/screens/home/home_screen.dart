import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/services/sermon_service.dart';
import '../../../data/models/sermon_model.dart';
import '../auth/login_screen.dart';
import '../sermon/sermon_list_screen.dart';
import '../sermon/sermon_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SermonService _sermonService = SermonService();
  String _churchName = '';
  SermonModel? _latestSermon;
  bool _isLoading = true;
  String? _churchCode;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final code = await _authService.getSavedChurchCode();
      if (code != null && code.isNotEmpty) {
        final churchData = await _authService.verifyChurchCode(code);
        final sermon = await _sermonService.getLatestSermon(code);
        if (mounted) {
          setState(() {
            _churchCode = code;
            _churchName = churchData?['name'] as String? ?? '';
            _latestSermon = sermon;
          });
        }
      }
    } catch (_) {
      // 오류 시 빈 상태로 표시
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  String _getTodayDevotion() {
    if (_latestSermon == null) return '';
    final weekday = DateTime.now().weekday; // 1(월)~7(일)
    if (weekday >= 1 && weekday <= 5) {
      return _latestSermon!.devotionals['day$weekday'] ?? '';
    }
    return '주중 묵상은 월요일부터 금요일까지입니다';
  }

  String _getTodayDayName() {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return '${days[DateTime.now().weekday - 1]}요일';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeCard(churchName: _churchName),

              const SizedBox(height: 20),

              if (_latestSermon != null) ...[
                _LatestSermonCard(
                  sermon: _latestSermon!,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SermonDetailScreen(sermon: _latestSermon!),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                _TodayDevotionCard(
                  dayName: _getTodayDayName(),
                  devotion: _getTodayDevotion(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SermonDetailScreen(sermon: _latestSermon!),
                      ),
                    );
                  },
                ),
              ] else
                _EmptySermonCard(),

              const SizedBox(height: 20),

              _QuickMenu(
                onSermonListTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SermonListScreen(),
                    ),
                  );
                },
                onDevotionTap: _latestSermon != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SermonDetailScreen(
                              sermon: _latestSermon!,
                              initialTabIndex: 2,
                            ),
                          ),
                        );
                      }
                    : null,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── 환영 카드 ──────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String churchName;

  const _WelcomeCard({required this.churchName});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 32),
          const SizedBox(height: 12),
          const Text(
            '안녕하세요! 🙏',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '오늘도 말씀과 함께하세요',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          if (churchName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.church, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    churchName,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── 최신 설교 카드 ─────────────────────────────────
class _LatestSermonCard extends StatelessWidget {
  final SermonModel sermon;
  final VoidCallback onTap;

  const _LatestSermonCard({required this.sermon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이번 주 설교',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sermon.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        sermon.formattedDate,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.menu_book,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        sermon.bibleVerse,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sermon.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '자세히 보기',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 16, color: AppColors.primary),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 오늘의 묵상 카드 ───────────────────────────────
class _TodayDevotionCard extends StatelessWidget {
  final String dayName;
  final String devotion;
  final VoidCallback onTap;

  const _TodayDevotionCard({
    required this.dayName,
    required this.devotion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 묵상',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: AppColors.secondary.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
                color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    devotion.isEmpty
                        ? '주중 묵상은 월~금요일에 제공됩니다'
                        : devotion,
                    style: TextStyle(
                      fontSize: 15,
                      color: devotion.isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 설교 없음 카드 ─────────────────────────────────
class _EmptySermonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.textHint.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              '아직 설교가 없습니다',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 빠른 메뉴 ──────────────────────────────────────
class _QuickMenu extends StatelessWidget {
  final VoidCallback onSermonListTap;
  final VoidCallback? onDevotionTap;

  const _QuickMenu({
    required this.onSermonListTap,
    this.onDevotionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 기능',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.menu_book,
                label: '설교 노트',
                color: AppColors.primary,
                onTap: onSermonListTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickMenuItem(
                icon: Icons.calendar_today,
                label: '주중 묵상',
                color: AppColors.secondary,
                onTap: onDevotionTap ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
