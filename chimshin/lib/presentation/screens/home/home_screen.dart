import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../data/services/sermon_service.dart';
import '../../../data/services/progress_service.dart';
import '../../../data/models/sermon_model.dart';
import '../../../data/models/user_progress_model.dart';
import '../auth/login_screen.dart';
import '../sermon/sermon_list_screen.dart';
import '../sermon/sermon_detail_screen.dart';
import '../saved/saved_sermons_screen.dart';
import '../devotion/devotionals_screen.dart';
import '../prayer/prayer_requests_screen.dart';
import '../../../data/services/saved_sermon_service.dart';
import '../../../data/services/prayer_service.dart';
import '../../../data/models/prayer_request_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/daily_bible_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SermonService _sermonService = SermonService();
  final ProgressService _progressService = ProgressService();
  final _savedService = SavedSermonService();
  final _prayerService = PrayerService();
  String _churchName = '';
  SermonModel? _latestSermon;
  UserProgressModel? _latestProgress;
  List<SermonModel> _savedSermons = [];
  bool _isLoading = true;
  String? _churchCode;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
    SavedSermonService.changeNotifier.addListener(_onSavedChange);
  }

  void _onSavedChange() => _loadSavedSermons();

  @override
  void dispose() {
    SavedSermonService.changeNotifier.removeListener(_onSavedChange);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final code = await _authService.getSavedChurchCode();
      if (code != null && code.isNotEmpty) {
        final churchData = await _authService.verifyChurchCode(code);
        final sermon = await _sermonService.getLatestSermon(code);
        UserProgressModel? progress;
        if (sermon != null) {
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            progress = await _progressService.getProgress(userId, sermon.id);
          }
        }
        if (mounted) {
          setState(() {
            _churchCode = code;
            _churchName = churchData?['name'] as String? ?? '';
            _latestSermon = sermon;
            _latestProgress = progress;
          });
        }
      }
    } catch (_) {
      // 오류 시 빈 상태로 표시
    }

    await _loadSavedSermons();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSavedSermons() async {
    final saved = await _savedService.getSavedSermons();
    if (mounted) setState(() => _savedSermons = saved);
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

              const _DailyBibleCard(),

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
                    ).then((_) { if (mounted) _loadData(); });
                  },
                ),

                const SizedBox(height: 20),

                _TodayDevotionCard(
                  dayName: _getTodayDayName(),
                  devotion: _getTodayDevotion(),
                  progress: _latestProgress,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            DevotionalsScreen(sermon: _latestSermon!),
                      ),
                    ).then((_) { if (mounted) _loadData(); });
                  },
                ),
              ] else
                _EmptySermonCard(),

              const SizedBox(height: 20),

              _SavedSermonsSection(
                savedSermons: _savedSermons,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SavedSermonsScreen()),
                ).then((_) => _loadSavedSermons()),
                onTap: (sermon) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SermonDetailScreen(sermon: sermon)),
                ).then((_) => _loadSavedSermons()),
              ),

              const SizedBox(height: 20),

              if (_uid != null)
                _PrayerSection(
                  uid: _uid!,
                  prayerService: _prayerService,
                  onManage: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrayerRequestsScreen()),
                  ),
                ),

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
                            builder: (context) =>
                                DevotionalsScreen(sermon: _latestSermon!),
                          ),
                        ).then((_) { if (mounted) _loadData(); });
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
  final UserProgressModel? progress;
  final VoidCallback onTap;

  const _TodayDevotionCard({
    required this.dayName,
    required this.devotion,
    this.progress,
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
                  Row(
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
                      const Spacer(),
                      // 주간 진행 현황
                      if (progress != null)
                        Text(
                          '${progress!.completedCount}/5일 완료',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress!.completedCount / 5,
                        backgroundColor:
                            AppColors.secondary.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 6,
                      ),
                    ),
                  ],
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

// ─── 저장한 설교 섹션 ────────────────────────────────
class _SavedSermonsSection extends StatelessWidget {
  final List<SermonModel> savedSermons;
  final VoidCallback onViewAll;
  final void Function(SermonModel) onTap;

  const _SavedSermonsSection({
    required this.savedSermons,
    required this.onViewAll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = savedSermons.take(3).toList();
    final total = savedSermons.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 행
        Row(
          children: [
            const Text(
              '저장한 설교',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '총 $total개',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const Spacer(),
            if (total > 0)
              GestureDetector(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      '전체 보기',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18, color: AppColors.primary),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // 저장 없음
        if (total == 0)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: AppColors.textHint.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.bookmark_border,
                      size: 36, color: Colors.grey.shade300),
                  const SizedBox(width: 14),
                  const Text(
                    '저장한 설교가 없습니다',
                    style: TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          )
        else
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                ...preview.asMap().entries.map((e) {
                  final idx = e.key;
                  final sermon = e.value;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => onTap(sermon),
                        borderRadius: BorderRadius.only(
                          topLeft: idx == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
                          topRight: idx == 0
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomLeft: idx == preview.length - 1
                              ? const Radius.circular(12)
                              : Radius.zero,
                          bottomRight: idx == preview.length - 1
                              ? const Radius.circular(12)
                              : Radius.zero,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sermon.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${sermon.date.month}월 ${sermon.date.day}일',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: AppColors.textHint),
                            ],
                          ),
                        ),
                      ),
                      if (idx < preview.length - 1)
                        Divider(
                            height: 1,
                            indent: 14,
                            endIndent: 14,
                            color: AppColors.primary.withValues(alpha: 0.08)),
                    ],
                  );
                }),
                // "전체 보기" 버튼 (3개 초과 시)
                if (total > 3) ...[
                  Divider(
                      height: 1,
                      color: AppColors.primary.withValues(alpha: 0.08)),
                  InkWell(
                    onTap: onViewAll,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          '전체 보기 ›',
                          style: TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
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

// --- 나의 기도제목 섹션 ---
class _PrayerSection extends StatelessWidget {
  final String uid;
  final PrayerService prayerService;
  final VoidCallback onManage;

  const _PrayerSection({
    required this.uid,
    required this.prayerService,
    required this.onManage,
  });

  Color _categoryColor(String category) {
    switch (category) {
      case '가족': return Colors.orange.shade300;
      case '직장': return Colors.blue.shade300;
      case '건강': return Colors.red.shade300;
      case '교회': return Colors.green.shade300;
      case '개인': return Colors.purple.shade300;
      default:    return Colors.grey.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '나의 기도제목',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onManage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '관리하기',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        StreamBuilder<List<PrayerRequestModel>>(
          stream: prayerService.prayerStream(uid),
          builder: (context, snapshot) {
            final prayers = snapshot.data ?? [];
            final sorted = List.of(prayers)
              ..sort((a, b) {
                if (a.isAnswered == b.isAnswered) return 0;
                return a.isAnswered ? 1 : -1;
              });
            final display = sorted.take(3).toList();

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: AppColors.secondary.withValues(alpha: 0.2),
                ),
              ),
              child: display.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Text('🙏', style: TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Text(
                            '기도제목을 추가해보세요',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        ...display.asMap().entries.map((e) {
                          final idx = e.key;
                          final prayer = e.value;
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _categoryColor(prayer.category),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prayer.category,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        prayer.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                          decoration: prayer.isAnswered
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (prayer.isAnswered)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '응답',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (idx < display.length - 1)
                                Divider(
                                    height: 1,
                                    indent: 14,
                                    endIndent: 14,
                                    color: Colors.grey.withValues(alpha: 0.1)),
                            ],
                          );
                        }),
                        if (prayers.length > 3) ...[
                          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),
                          InkWell(
                            onTap: onManage,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Center(
                                child: Text(
                                  '전체 보기 >',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            );
          },
        ),

        const SizedBox(height: 12),
        const _RepresentPrayerPromo(),
      ],
    );
  }
}

// ─── 오늘의 성경 카드 ───────────────────────────────
class _DailyBibleCard extends StatelessWidget {
  const _DailyBibleCard();

  static const _bibleAppPackage = 'com.bible_app.king_beginner_bible';
  static const _bibleAppStore =
      'https://play.google.com/store/apps/details?id=com.bible_app.king_beginner_bible';

  Future<void> _openBibleApp() async {
    final appUri = Uri.parse('android-app://$_bibleAppPackage');
    final storeUri = Uri.parse(_bibleAppStore);
    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(storeUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(storeUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DailyBibleData.getToday();
    final book = today['book'] as String;
    final chapter = today['chapter'] as int;
    final progress = DailyBibleData.getTodayProgress();

    final now = DateTime.now();
    final dateStr = '${now.month}월 ${now.day}일';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘의 성경',
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
            side: BorderSide(color: const Color(0xFFB8860B).withValues(alpha: 0.25)),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFFDF0), Color(0xFFFFF8E1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$book $chapter장',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF8D6E63),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFD7CCC8),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB8860B)),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '신약 연간 읽기 ${(progress * 100).toStringAsFixed(0)}% 완료',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8D6E63),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openBibleApp,
                    icon: const Icon(Icons.menu_book, size: 18),
                    label: const Text('왕초보 성경통독으로 읽기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB8860B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── 대표기도 앱 교차 홍보 배너 ─────────────────────
class _RepresentPrayerPromo extends StatelessWidget {
  const _RepresentPrayerPromo();

  static const _storeUrl =
      'https://play.google.com/store/apps/details?id=com.nanoset.repre_prayer_app';

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openStore,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Row(
          children: [
            const Text('🙏', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '더 많은 대표기도문이 필요하신가요?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '대표기도 앱 · 상황별 기도문 모음',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF66BB6A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.green.shade400),
          ],
        ),
      ),
    );
  }
}
