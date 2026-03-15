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
import '../devotion/group_devotion_screen.dart';
import '../notice/notice_screen.dart';
import '../prayer/prayer_requests_screen.dart';
import '../../../data/services/saved_sermon_service.dart';
import '../../../data/services/prayer_service.dart';
import '../../../data/services/activity_service.dart';
import '../../../data/services/admin_service.dart';
import '../admin/sermon_register_screen.dart';
import '../admin/members_screen.dart';
import '../../../data/services/member_service.dart';
import '../../../data/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'widgets/welcome_card.dart';
import 'widgets/latest_sermon_card.dart';
import 'widgets/today_devotion_card.dart';
import 'widgets/daily_bible_card.dart';
import 'widgets/prayer_section.dart';
import 'widgets/group_devotion_section.dart';
import 'widgets/weekly_activity_card.dart';
import 'widgets/saved_sermons_section.dart';
import 'widgets/quick_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _sermonService = SermonService();
  final _progressService = ProgressService();
  final _savedService = SavedSermonService();
  final _prayerService = PrayerService();
  final _activityService = ActivityService();

  String _churchName = '';
  String? _churchCode;
  String? _uid;
  SermonModel? _latestSermon;
  UserProgressModel? _latestProgress;
  List<SermonModel> _savedSermons = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  int _weeklySermon = 0;
  int _weeklyDevotion = 0;
  int _weeklyBible = 0;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    _loadData();
    _loadActivityStats();
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
        final adminResult = await AdminService().isAdmin(code);
        // 홈화면 접속 기록 (미출석 감지용)
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await MemberService.recordActivity(churchCode: code, uid: uid);
        }
        // FCM 토큰을 members 컬렉션에 동기화 (기도 알림 수신용)
        if (uid != null) {
          final token = await FirebaseMessaging.instance.getToken();
          if (token != null) {
            await MemberService.syncFcmToken(
              churchCode: code,
              uid: uid,
              fcmToken: token,
            );
            // 관리자면 church 문서에도 토큰 저장 (생일 알림 수신용)
            if (adminResult) {
              await MemberService.saveAdminToken(
                churchCode: code,
                fcmToken: token,
              );
            }
          }
        }
        if (mounted) {
          setState(() {
            _churchCode = code;
            _churchName = churchData?['name'] as String? ?? '';
            _latestSermon = sermon;
            _latestProgress = progress;
            _isAdmin = adminResult;
          });
        }
      }
    } catch (_) {}

    await _loadSavedSermons();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadSavedSermons() async {
    final saved = await _savedService.getSavedSermons();
    if (mounted) setState(() => _savedSermons = saved);
  }

  Future<void> _loadActivityStats() async {
    final sermon = await _activityService.getWeeklyCount('sermon');
    final devotion = await _activityService.getWeeklyCount('devotion');
    final bible = await _activityService.getWeeklyCount('bible');
    final streak = await _activityService.updateAndGetStreak();
    if (mounted) {
      setState(() {
        _weeklySermon = sermon;
        _weeklyDevotion = devotion;
        _weeklyBible = bible;
        _streak = streak;
      });
    }
  }

  Future<void> _refreshAll() async {
    await _loadData();
    await _loadActivityStats();
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
    final weekday = DateTime.now().weekday;
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
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WelcomeCard(churchName: _churchName),
              const SizedBox(height: 20),

              if (_latestSermon != null) ...[
                LatestSermonCard(
                  sermon: _latestSermon!,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SermonDetailScreen(sermon: _latestSermon!),
                    ),
                  ).then((_) { if (mounted) _refreshAll(); }),
                ),
                const SizedBox(height: 20),
                TodayDevotionCard(
                  dayName: _getTodayDayName(),
                  devotion: _getTodayDevotion(),
                  progress: _latestProgress,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DevotionalsScreen(sermon: _latestSermon!),
                    ),
                  ).then((_) { if (mounted) _refreshAll(); }),
                ),
              ] else
                const EmptySermonCard(),

              const SizedBox(height: 20),
              const DailyBibleCard(),
              const SizedBox(height: 20),

              if (_uid != null)
                PrayerSection(
                  uid: _uid!,
                  prayerService: _prayerService,
                  onManage: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PrayerRequestsScreen()),
                  ),
                ),

              const SizedBox(height: 20),

              if (_latestSermon != null)
                GroupDevotionSection(
                  sermon: _latestSermon!,
                  progress: _latestProgress,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          GroupDevotionScreen(sermon: _latestSermon!),
                    ),
                  ).then((_) { if (mounted) _refreshAll(); }),
                ),

              const SizedBox(height: 20),

              WeeklyActivityCard(
                sermonDays: _weeklySermon,
                devotionDays: _weeklyDevotion,
                bibleDays: _weeklyBible,
                streak: _streak,
              ),
              const SizedBox(height: 20),

              SavedSermonsSection(
                savedSermons: _savedSermons,
                onViewAll: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SavedSermonsScreen()),
                ).then((_) => _loadSavedSermons()),
                onTap: (sermon) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SermonDetailScreen(sermon: sermon)),
                ).then((_) => _loadSavedSermons()),
              ),
              const SizedBox(height: 20),

              QuickMenu(
                onSermonListTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SermonListScreen()),
                ),
                onNoticeTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoticeScreen(
                      churchCode: _churchCode ?? '',
                      churchName: _churchName,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      floatingActionButton: _isAdmin
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  heroTag: 'members',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MembersScreen()),
                  ),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.people, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'sermon',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SermonRegisterScreen()),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('설교 등록',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                  backgroundColor: AppColors.primary,
                ),
              ],
            )
          : null,
    );
  }
}
